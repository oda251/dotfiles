include "root" {
  path = find_in_parent_folders("root.hcl")
}

dependency "common" {
  config_path  = "../common"
  skip_outputs = true
}

inputs = {
  newrelic_region = "US"
}
