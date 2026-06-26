use crate::service::hub::run_service;

use std::ffi::OsString;

use std::time::Duration;

use tokio::runtime::Runtime;

use windows_service::{
    define_windows_service,
    service::{
        ServiceControl, ServiceControlAccept, ServiceExitCode, ServiceState, ServiceStatus,
        ServiceType,
    },
    service_control_handler::{self, ServiceControlHandlerResult},
    service_dispatcher, Result,
};

const SERVICE_NAME: &str = "FlClashHelperService";

const SERVICE_TYPE: ServiceType = ServiceType::OWN_PROCESS;

pub fn main() -> Result<()> {
    start_service()
}

// NOTE: 修复函数名拼写错误 serveice -> service。
pub fn start_service() -> Result<()> {
    service_dispatcher::start(SERVICE_NAME, service)
}

define_windows_service!(service, service_main);

// NOTE: Runtime::new() 失败时静默返回，改为打印错误。
pub fn service_main(_arguments: Vec<OsString>) {
    match Runtime::new() {
        Ok(rt) => {
            rt.block_on(async {
                let _ = run_windows_service().await;
            });
        }
        Err(e) => {
            eprintln!("Failed to create runtime: {}", e);
        }
    }
}

async fn run_windows_service() -> anyhow::Result<()> {
    let status_handle = service_control_handler::register(
        SERVICE_NAME,
        move |event| -> ServiceControlHandlerResult {
            match event {
                ServiceControl::Interrogate => ServiceControlHandlerResult::NoError,
                // NOTE: exit(0) 会跳过 Drop 和异步清理。
                // 对于简单的 helper 服务可接受，因为子进程由 SCM 管理。
                ServiceControl::Stop => std::process::exit(0),
                _ => ServiceControlHandlerResult::NotImplemented,
            }
        },
    )?;

    // NOTE: 先报告 StartPending，再转 Running，SCM 规范要求。
    status_handle.set_service_status(ServiceStatus {
        service_type: SERVICE_TYPE,
        current_state: ServiceState::StartPending,
        controls_accepted: ServiceControlAccept::empty(),
        exit_code: ServiceExitCode::Win32(0),
        checkpoint: 0,
        wait_hint: Duration::from_secs(5),
        process_id: None,
    })?;

    run_service().await?;

    status_handle.set_service_status(ServiceStatus {
        service_type: SERVICE_TYPE,
        current_state: ServiceState::Running,
        controls_accepted: ServiceControlAccept::STOP,
        exit_code: ServiceExitCode::Win32(0),
        checkpoint: 0,
        wait_hint: Duration::default(),
        process_id: None,
    })?;

    // NOTE: 保持服务运行直到进程被 SCM 终止。
    std::future::pending::<()>().await;
    Ok(())
}




