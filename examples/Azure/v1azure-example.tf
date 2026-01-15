# DEPRECATED
#
# This example root module is intentionally disabled to avoid duplicate provider/module
# definitions when running Terraform from examples/Azure/.
#
# Use one of these instead:
# - examples/Azure/azure-example.tf
# - examples/Azure/one-click/
#
# The original file contents are preserved in v1azure-example.tf.txt.
/*
DEPRECATED EXAMPLE (disabled)

Terraform loads every *.tf file in this folder. This file used to be a second Azure example,
but it conflicts with azure-example.tf (duplicate providers + module name) when you run
terraform plan/apply from examples/Azure.

The original content is preserved in v1azure-example.tf.txt for reference.

If you want the “one-click” Azure deployment, run Terraform from examples/Azure/one-click instead.
*/