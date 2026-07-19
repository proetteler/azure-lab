# azure-lab

Azure Lab-Umgebung als Infrastructure as Code (Terraform).
Zwei-Schichten-Architektur nach dem Prinzip **"cattle, not pets"**:
Die VM ist wegwerfbar, die Daten überleben.

```
infra/
├── persistent/   # Schicht 1: Data Disk – wird NIE destroyed
└── vm/           # Schicht 2: Netzwerk + VM – nach jeder Session destroyed
```

## Architektur

| Schicht | Ressourcen | Lebensdauer | Kosten (idle) |
|---|---|---|---|
| `persistent/` | RG + 32 GB Data Disk | dauerhaft | ~1.50 CHF/Mt |
| `vm/` | VNet, NSG, IP, NIC, B1s-VM | pro Session | 0 (nach destroy) |

Die VM mountet den Data Disk unter `/data`. Dort liegen AI-Agent-Projekte,
Docker-Volumes etc. – ein `terraform destroy` im `vm/`-Projekt lässt sie
unberührt, weil der Disk der persistenten Schicht *gehört* und im
`vm/`-Projekt nur per **data source** referenziert wird.

Cloud-init richtet jede frische VM beim ersten Boot automatisch ein:
Docker, Python, uv, Mount von `/data`.

## Ersteinrichtung (einmalig)

```bash
brew install terraform azure-cli   # macOS
az login
ssh-keygen -t ed25519              # falls noch kein Key existiert

# Persistente Schicht deployen – danach in Ruhe lassen
cd infra/persistent
terraform init
terraform apply
```

## Workflow pro Übungssession

```bash
cd infra/vm
terraform init        # nur beim allerersten Mal
terraform apply       # ~3 Min → VM steht, cloud-init läuft
ssh patrick@<ip>      # IP steht im Terraform-Output
cloud-init status --wait   # optional: warten bis Setup fertig

# ... arbeiten, Daten nach /data ...

terraform destroy     # Session-Ende: VM & Netzwerk weg, /data-Disk bleibt
```

## Alternativ: VM behalten statt destroyen

```bash
az vm deallocate -g rg-lab -n vm-lab-01   # stoppt Compute-Kosten
az vm start -g rg-lab -n vm-lab-01
```

Restkosten dann: OS-Disk + Public IP (~5 CHF/Mt zusätzlich zum Data Disk).

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
- `prevent_destroy` schützt den Data Disk vor versehentlichem Löschen
