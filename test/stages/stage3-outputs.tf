
resource local_file write_outputs {
  filename = "gitops-output.json"

  content = jsonencode({
    name        = module.ace.name
    branch      = module.ace.branch
    namespace   = module.ace.namespace
    server_name = module.ace.server_name
    layer       = module.ace.layer
    layer_dir   = module.ace.layer == "infrastructure" ? "1-infrastructure" : (module.ace.layer == "services" ? "2-services" : "3-applications")
    type        = module.ace.type
  })
}
