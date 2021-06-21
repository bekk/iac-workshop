// This file, together with the scripts in the 'hacks' directory contains dirty
// hacks to show how a frontend can be deployed using terrform, as an example
// of how powerful and flexible terraform can be.

// Please note: The fact that you can do it, does not mean that you should do
// it. These hacks does not represent best practices, nor how we would do it
// for most normal code bases.

// Runs the hacks/etag.sh script, which returns a json object on the format
// `{"etag": "<etag>"}`.  The etag will change when the frontend changes, and
// other resources can use it to decide whether to do changes.
// Note: This is done during the *plan* phase.
/* This comment will be removed during the tutorial
data "external" "frontend-zip-etag" {
  program = ["${path.module}/hacks/etag.sh", var.frontend_zip]
}

// This resource is recreated whenever one of values in the triggers block
// changes. In this case, it will change when the frontend etag changes.
resource "null_resource" "frontend-payload" {
  triggers = {
    zip_file_etag = data.external.frontend-zip-etag.result["etag"]
  }

  // Run the hacks/frontend.sh script, that deploys the frontend.
  provisioner "local-exec" {
    command = "${path.module}/hacks/frontend.sh ${var.frontend_zip} http://${azurerm_container_group.backend.fqdn}:8080/api ${azurerm_storage_account.web.name} ${azurerm_storage_account.web.primary_access_key}"
  }
}
*/