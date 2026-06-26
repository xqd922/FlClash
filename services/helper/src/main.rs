#[cfg(not(all(feature = "windows-service", target_os = "windows")))]
use tokio::runtime::Runtime;
#[cfg(not(all(feature = "windows-service", target_os = "windows")))]
use crate::service::hub::run_service;

mod service;

#[cfg(all(feature = "windows-service", target_os = "windows"))]
pub fn main() -> windows_service::Result<()> {
    service::windows::main()
}

// NOTE: 修复两个问题：
// 1. Runtime::new() 失败时静默返回 0（成功），改为打印错误并退出。
// 2. run_service() 结果被丢弃，端口冲突等错误无法排查。
#[cfg(not(all(feature = "windows-service", target_os = "windows")))]
fn main() {
    match Runtime::new() {
        Ok(rt) => {
            rt.block_on(async {
                if let Err(e) = run_service().await {
                    eprintln!("Service failed: {}", e);
                    std::process::exit(1);
                }
            });
        }
        Err(e) => {
            eprintln!("Failed to create runtime: {}", e);
            std::process::exit(1);
        }
    }
}
