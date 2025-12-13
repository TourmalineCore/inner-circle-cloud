// This service account is used to enable VM when it was disabled
resource "yandex_iam_service_account" "restart_vm_service_account" {
  name      = format("%s-restart-vm-service-account", local.resource_name_prefix)
}

// Grant functions.functionInvoker permission for created service account to invoke restart functions
resource "yandex_resourcemanager_folder_iam_member" "restart_vm_service_account_function_invoker_iam" {
  folder_id = var.folder_id
  role      = "functions.functionInvoker"
  member    = "serviceAccount:${yandex_iam_service_account.restart_vm_service_account.id}"
}

// Grant compute.operator permission for created service account to manage VM state
resource "yandex_resourcemanager_folder_iam_member" "restart_vm_service_account_compute_operator_iam" {
  folder_id = var.folder_id
  role      = "compute.operator"
  member    = "serviceAccount:${yandex_iam_service_account.restart_vm_service_account.id}"
}

resource "yandex_function" "start-vm-function" {
  name               = "start-vm-function"
  user_hash          = "first function"
  runtime            = "nodejs18"
  entrypoint         = "index.handler"
  memory             = "128"
  execution_timeout  = "3"
  service_account_id = yandex_iam_service_account.restart_vm_service_account.id
  folder_id = var.folder_id
  environment = {
    FOLDER_ID = var.folder_id
    INSTANCE_ID = yandex_compute_instance.vm.id
  }
  content {
    zip_filename = "./start-function-js/function-js.zip"
  }
}

resource "yandex_function" "stop-vm-function" {
  name               = "stop-vm-function"
  user_hash          = "first function"
  runtime            = "nodejs18"
  entrypoint         = "index.handler"
  memory             = "128"
  execution_timeout  = "3"
  service_account_id = yandex_iam_service_account.restart_vm_service_account.id
  folder_id = var.folder_id
  environment = {
    FOLDER_ID = var.folder_id
    INSTANCE_ID = yandex_compute_instance.vm.id
  }
  content {
    zip_filename = "./stop-function-js/function-js.zip"
  }
}


resource "yandex_function_trigger" "start-timer" {
  name        = "start-timer"
  timer {
    cron_expression = "30 1 ? * MON-FRI *"
  }
  function {
    id = yandex_function.start-vm-function.id
    service_account_id = yandex_iam_service_account.restart_vm_service_account.id
  }
}

resource "yandex_function_trigger" "stop-timer" {
  name        = "stop-timer"
  timer {
    cron_expression = "0 16 ? * MON-FRI * "
  }
  function {
    id = yandex_function.stop-vm-function.id
    service_account_id = yandex_iam_service_account.restart_vm_service_account.id
  }
}
