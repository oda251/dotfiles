include "root" {
  path = find_in_parent_folders()
}

inputs = {
  grafana_stack_slug   = "oda251"
  grafana_stack_region = "ap-northeast-0"
}
