## 2.0.0 - 2025-05-11

### Changed
- **BREAKING**: Bumped `azurerm` provider to `~> 4.20` (was `~> 3.116`).
- Bumped Terraform required version to `>= 1.10` (was `>= 1.9`).
- Added `azapi ~> 2.0` to `required_providers` for fleet alignment.
- Renamed azurerm_network_interface attributes: `enable_ip_forwarding` → `ip_forwarding_enabled`, `enable_accelerated_networking` → `accelerated_networking_enabled`.
- Module already uses `azurerm_linux_virtual_machine` and `azurerm_windows_virtual_machine` (no legacy `azurerm_virtual_machine` migration needed).
- `disable_password_authentication` semantics preserved (no changes).

### Notes
- Cross-module dependency: sibling overlays sourced via `github.com/POps-Rox/...` must publish their own 4.x release before this module can be consumed against the un-patched constraint set.
- The commented-out `azurerm_monitor_diagnostic_setting` resource already had `retention_policy` blocks (no removal needed).

# v1.0.0 - <date>

Added
- Exposed paramters to configure Azure Spot instanaces
  of azurerm_linux_virtual_machine and azurerm_windows_virtual_machine
  Terraform ressources, so that the Spot instances can be deployed 
  with this module
