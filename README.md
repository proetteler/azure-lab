# azure-lab

Azure Lab-Umgebung als Infrastructure as Code (Terraform).

```
infra/
├── persistent/   # Data Disk – im Repo vorbereitet, aktuell NICHT deployed
└── vm/           # Netzwerk + VM – wird pro Session deployed und destroyed
```

## Architektur

Aktuell wird nur `vm/` deployed: eine wegwerfbare Lab-VM
("cattle, not pets") mit eigenem Netzwerk, die nach jeder Session per
`terraform destroy` wieder komplett verschwindet. Es gibt derzeit
keinen persistenten Storage – Daten auf der VM überleben einen
`destroy` nicht.

`infra/persistent/` (RG + Data Disk) bleibt als vorbereitete zweite
Schicht im Repo, wird aber bewusst nicht deployed. Soll sie später
genutzt werden, braucht `vm/` wieder eine `data`-Referenz auf den
Disk plus ein `azurerm_virtual_machine_data_disk_attachment` sowie
die passende Mount-Logik in `cloud-init.yaml`.

| Schicht | Ressourcen | Status |
|---|---|---|
| `persistent/` | RG + 32 GB Data Disk | im Repo, **nicht deployed** |
| `vm/` | VNet, NSG, IP, NIC, B1s-VM | pro Session deployed/destroyed |

Cloud-init richtet jede frische VM beim ersten Boot automatisch ein:
Docker, Python, uv.

## Ersteinrichtung (einmalig)

```bash
brew install terraform azure-cli   # macOS
az login
ssh-keygen -t ed25519              # falls noch kein Key existiert
```

## Workflow pro Übungssession

```bash
cd infra/vm
terraform init        # nur beim allerersten Mal
terraform apply       # ~3 Min → VM steht, cloud-init läuft
ssh patrick@<ip>      # IP steht im Terraform-Output
cloud-init status --wait   # optional: warten bis Setup fertig

# ... arbeiten ...

terraform destroy     # Session-Ende: VM & Netzwerk komplett weg
```

## Alternativ: VM behalten statt destroyen

```bash
az vm deallocate -g rg-lab -n vm-lab-01   # stoppt Compute-Kosten
az vm start -g rg-lab -n vm-lab-01
```

Restkosten dann: OS-Disk + Public IP (~5 CHF/Mt).

## Nützliche Varianten

```bash
# SSH nur von der eigenen IP erlauben
terraform apply -var="allowed_ssh_source=$(curl -s ifconfig.me)/32"

# Grössere VM für Docker-lastige AI-Arbeit (2 vCPU / 4 GB RAM)
terraform apply -var="vm_size=Standard_B2s"
```

## Sicherheit / Konventionen

- `terraform.tfstate` und `*.tfvars` sind gitignored – **nie committen**
- Keine Secrets im Code: API-Keys als Env-Variablen auf der VM,
  später via Azure Key Vault
- `persistent/` nutzt `prevent_destroy`, um den Data Disk vor
  versehentlichem Löschen zu schützen, sobald diese Schicht
  einmal deployed wird
