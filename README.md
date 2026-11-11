# OpenTofu auf AWS – Lab

Infrastructure as Code mit [OpenTofu](https://opentofu.org/) auf einem eigenen AWS-Konto. Begonnen im August 2026 während meiner Umschulung zum Fachinformatiker für Systemintegration.

Ziel ist der sichere Umgang mit dem kompletten Lebenszyklus von Infrastruktur, also Anlegen, Ändern, Abreißen und Nachweisen, dass nichts übrig bleibt. Die Projekte sind deshalb bewusst klein.

| Ordner | Inhalt | Eigener Code |
|---|---|---|
| [`01-iam-demo`](01-iam-demo/) | Kompletter Ablauf an einer kostenlosen Ressource: `init` → `plan` → `apply` → Outputs → Änderung in-place → Replace → `destroy` → Gegenprobe in AWS | ja |
| [`02-tofuparty-lab`](02-tofuparty-lab/) | Betrieb eines fremden Produktiv-Stacks (CloudFront → ALB → ECS Fargate → EFS): analysieren, deployen, prüfen, rückstandsfrei abbauen | nein, nur die Dokumentation |
| `03-ec2-efs` | *geplant:* EC2-Instanz mit EFS-Mount per user-data, Security Groups, eigene VPC-Verdrahtung | – |

## Grundsätze in allen Projekten

- **Keine Zugangsdaten im Code.** OpenTofu nutzt die Credential-Chain der AWS CLI. Dafür gibt es einen eigenen IAM-User `tofu-admin` nur mit programmatischem Zugriff. Er bekommt seine Rechte über eine IAM-Gruppe, nicht direkt.
- **State nie im Repository.** `terraform.tfstate` enthält alle Attribute im Klartext. Die [`.gitignore`](.gitignore) stand vor dem ersten `apply`, und die Commit-Historie zeigt, dass der State nie eingecheckt wurde.
- **Lock-Datei im Repository.** `.terraform.lock.hcl` legt die Provider-Version samt Prüfsummen fest.
- **Ein Ordner = ein State.** Die Projekte sind voneinander unabhängig.
- **Jede Session endet mit `destroy` und einer Gegenprobe gegen AWS.** Ein leerer State beweist nur, dass OpenTofu *glaubt*, fertig zu sein.

## Kostenkontrolle

Das Konto läuft im kreditbasierten AWS Free Plan (Konten ab Juli 2025). Es gibt keine dauerhaften Freikontingente, jede laufende Ressource zieht vom Guthaben ab. Deshalb:

- Ein Budget-Alarm bei 5 $.
- Alles, was Kosten verursacht, wird in derselben Session wieder abgerissen.
- Nach dem Abbau prüfe ich jede Ressourcenart, die Kosten verursacht, direkt per AWS CLI. Ich verlasse mich nicht allein auf den State.

## Voraussetzungen

- OpenTofu ≥ 1.6
- AWS CLI v2 mit konfiguriertem Profil (`aws configure`)
- Region: `eu-central-1` (Frankfurt)

## Lizenz

Eigene Dateien stehen unter der [MIT-Lizenz](LICENSE). Für den in `02-tofuparty-lab` beschriebenen Stack gelten die Bedingungen seines Original-Repositorys.
