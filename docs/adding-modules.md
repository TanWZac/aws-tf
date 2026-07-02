# Adding New Modules

Use this workflow to add new resources safely and consistently.

1. Create module scaffold:
   ./scripts/new-module.sh <module_name>

2. Implement module resources in modules/<module_name>/main.tf.

3. Define module inputs/outputs in modules/<module_name>/variables.tf and outputs.tf.

4. Wire the module in root main.tf.

5. Add root variables and outputs in variables.tf and outputs.tf.

6. Validate all environments:
   make fmt
   make init ENV=dev
   make validate
   make plan ENV=dev
   make plan ENV=stage
   make plan ENV=prod

7. Open a PR from a feature branch and ensure CI passes.
