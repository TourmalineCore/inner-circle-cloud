// This service account is used to enable/disable VM according to schedule
resource "yandex_iam_service_account" "vm_state_manager_service_account" {
  name = format("%s-vm-state-manager-service-account", local.resource_name_prefix)
}

// Grant functions.functionInvoker permission for created service account to invoke cloud functions. (e.g. start/stop VM function) 
resource "yandex_resourcemanager_folder_iam_member" "vm_state_manager_service_account_function_invoker_iam" {
  folder_id = var.folder_id
  role = "functions.functionInvoker"
  member = "serviceAccount:${yandex_iam_service_account.vm_state_manager_service_account.id}"
}

// Grant compute.operator permission for created service account to manage VM state
resource "yandex_resourcemanager_folder_iam_member" "vm_state_manager_service_account_compute_operator_iam" {
  folder_id = var.folder_id
  role = "compute.operator"
  member = "serviceAccount:${yandex_iam_service_account.vm_state_manager_service_account.id}"
}

resource "yandex_function" "start_vm_function" {
  name = format("%s-start-vm-function", local.resource_name_prefix)
  // time stamp for user hash is used to update uploaded functions-js.zip archive content
  user_hash = "${timestamp()}"
  runtime = "nodejs18"
  entrypoint = "index.handler"
  memory = "128"
  execution_timeout = "3"
  service_account_id = yandex_iam_service_account.vm_state_manager_service_account.id
  folder_id = var.folder_id
  environment = {
    FOLDER_ID = var.folder_id
    INSTANCE_ID = yandex_compute_instance.vm.id
  }
  content {
    zip_filename = "./start-vm-function/function-js.zip"
  }
}

resource "yandex_function" "stop_vm_function" {
  name = format("%s-stop-vm-function", local.resource_name_prefix)
  // time stamp for user hash is used to update uploaded functions-js.zip archive content
  user_hash = "${timestamp()}"
  runtime = "nodejs18"
  entrypoint = "index.handler"
  memory = "128"
  execution_timeout = "3"
  service_account_id = yandex_iam_service_account.vm_state_manager_service_account.id
  folder_id = var.folder_id
  environment = {
    FOLDER_ID = var.folder_id
    INSTANCE_ID = yandex_compute_instance.vm.id
  }
  content {
    zip_filename = "./stop-vm-function/function-js.zip"
  }
}

resource "yandex_function_trigger" "start_vm_trigger" {
  name = format("%s-start-vm-trigger", local.resource_name_prefix)
  timer {
    // Start VM at 1:30 AM (UTC+0) every day from monday to friday
    cron_expression = var.start_vm_cron_expression
  }
  function {
    id = yandex_function.start_vm_function.id
    service_account_id = yandex_iam_service_account.vm_state_manager_service_account.id
  }
}

resource "yandex_function_trigger" "stop_vm_trigger" {
  name = format("%s-stop-vm-trigger", local.resource_name_prefix)
  timer {
    // Disable VM at 4:00 PM (UTC+0) every day from monday to friday
    cron_expression = var.stop_vm_cron_expression
  }
  function {
    id = yandex_function.stop_vm_function.id
    service_account_id = yandex_iam_service_account.vm_state_manager_service_account.id
  }
}
