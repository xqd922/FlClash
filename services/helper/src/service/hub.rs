// NOTE: 用 std::sync::LazyLock 替代 once_cell（Rust 2021 edition + 1.80+ 支持）。
use std::sync::LazyLock;
use serde::{Deserialize, Serialize};
use sha2::{Digest, Sha256};
use std::collections::VecDeque;
use std::fs::File;
use std::io::{BufRead, Error, Read};
use std::process::{Command, Stdio};
use std::sync::{Arc, Mutex};
use std::{io, thread};
use warp::{Filter, Reply};

const LISTEN_PORT: u16 = 47890;

#[derive(Debug, Deserialize, Serialize, Clone)]
pub struct StartParams {
    pub path: String,
    pub arg: String,
}

fn sha256_file(path: &str) -> Result<String, Error> {
    let mut file = File::open(path)?;
    let mut hasher = Sha256::new();
    let mut buffer = [0; 4096];

    loop {
        let bytes_read = file.read(&mut buffer)?;
        if bytes_read == 0 {
            break;
        }
        hasher.update(&buffer[..bytes_read]);
    }

    Ok(format!("{:x}", hasher.finalize()))
}

static LOGS: LazyLock<Arc<Mutex<VecDeque<String>>>> =
    LazyLock::new(|| Arc::new(Mutex::new(VecDeque::with_capacity(100))));
static PROCESS: LazyLock<Arc<Mutex<Option<std::process::Child>>>> =
    LazyLock::new(|| Arc::new(Mutex::new(None)));

fn start(start_params: StartParams) -> impl Reply {
    // NOTE: 区分文件读取失败和哈希不匹配，方便排查。
    let sha256 = match sha256_file(start_params.path.as_str()) {
        Ok(hash) => hash,
        Err(e) => return format!("Failed to read core binary: {}", e),
    };
    if sha256 != env!("TOKEN") {
        return format!("The SHA256 hash of the program requesting execution is: {}. The helper program only allows execution of applications with the SHA256 hash: {}.", sha256,  env!("TOKEN"),);
    }
    stop();
    let mut process = PROCESS.lock().unwrap();
    match Command::new(&start_params.path)
        .stderr(Stdio::piped())
        .arg(&start_params.arg)
        .spawn()
    {
        Ok(child) => {
            *process = Some(child);
            if let Some(ref mut child) = *process {
                let stderr = child.stderr.take().unwrap();
                let reader = io::BufReader::new(stderr);
                thread::spawn(move || {
                    for line in reader.lines() {
                        match line {
                            Ok(output) => {
                                log_message(output);
                            }
                            Err(_) => {
                                break;
                            }
                        }
                    }
                });
            }
            "".to_string()
        }
        Err(e) => {
            log_message(e.to_string());
            e.to_string()
        }
    }
}

fn stop() -> impl Reply {
    let mut process = PROCESS.lock().unwrap();
    if let Some(mut child) = process.take() {
        let _ = child.kill();
        let _ = child.wait();
    }
    *process = None;
    "".to_string()
}

fn log_message(message: String) {
    let mut log_buffer = LOGS.lock().unwrap();
    if log_buffer.len() == 100 {
        log_buffer.pop_front();
    }
    log_buffer.push_back(format!("{}\n", message));
}

fn get_logs() -> impl Reply {
    let log_buffer = LOGS.lock().unwrap();
    let value = log_buffer
        .iter()
        .cloned()
        .collect::<Vec<String>>()
        .join("\n");
    warp::reply::with_header(value, "Content-Type", "text/plain")
}

pub async fn run_service() -> anyhow::Result<()> {
    let api_ping = warp::get().and(warp::path("ping")).map(|| env!("TOKEN"));

    // NOTE: 添加 16KB 请求体大小限制，防止恶意超大 JSON 耗尽内存。
    let api_start = warp::post()
        .and(warp::path("start"))
        .and(warp::body::content_length_limit(1024 * 16))
        .and(warp::body::json())
        .map(|start_params: StartParams| start(start_params));

    let api_stop = warp::post().and(warp::path("stop")).map(|| stop());

    let api_logs = warp::get().and(warp::path("logs")).map(|| get_logs());

    warp::serve(api_ping.or(api_start).or(api_stop).or(api_logs))
        .run(([127, 0, 0, 1], LISTEN_PORT))
        .await;

    Ok(())
}
