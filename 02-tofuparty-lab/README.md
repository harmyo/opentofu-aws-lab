# 02 – tofuparty: einen fremden Stack betreiben

Eine Schulübung im August 2026. Der Stack stammt nicht von mir, sondern aus [`gretel/tofuparty`](https://github.com/gretel/tofuparty/tree/ac987df) (Stand `ac987df`, 06.08.2026). Das Repository hat sich seitdem weiterentwickelt. Diese Dokumentation bezieht sich auf den genannten Stand.

**Mein Anteil:** Ich habe den Stack in meinem eigenen AWS-Konto analysiert, deployt, geprüft und noch am selben Tag rückstandsfrei abgebaut. Der Code ist deshalb nicht in diesem Repository enthalten, nur meine Dokumentation.

## Architektur

```
Browser → CloudFront (TLS) → Application Load Balancer (HTTP)
        → ECS Fargate (Container copyparty/ac) → EFS (Speicher)
```

Dazu kommen eine eigene VPC über zwei Availability Zones mit NAT Gateway und ein zufällig generiertes Passwort über den Provider `hashicorp/random`. Die Anwendung ist [copyparty](https://github.com/9001/copyparty), ein selbstgehosteter Dateiserver.

## Vorgehen

**1. Getrennt klonen.** Der Klon liegt bei mir unter `~/projekte/tofuparty`, nicht in diesem Repository. Ein Git-Repository innerhalb eines anderen würde Git als eingebettetes Repository behandeln. Außerdem ist es ein fremdes Projekt mit eigener Historie.

**2. Vor dem Deploy lesen.** In `variables.tf` und `locals.tf` ist mir aufgefallen:
- Alle Variablen haben Standardwerte. `apply` würde ohne jede Eingabe durchlaufen, auch mit dem Standard-Präfix.
- `local.name` ist das Präfix ohne Zufallszusatz. Zwei Deployments mit demselben Präfix im selben Konto würden kollidieren.
- ALB- und Target-Group-Namen sind bei AWS auf 32 Zeichen begrenzt. Das Präfix sollte deshalb höchstens 12 Zeichen haben.

**3. Präfix setzen.** `name_prefix = "fisi-lab"` steht in einer `terraform.tfvars`. Das ist reproduzierbar und wird von OpenTofu automatisch gelesen. Die Alternativen hatten Nachteile: Ein vergessenes `-var` beim nächsten `plan` hätte alle Ressourcen umbenennen wollen, also löschen und neu anlegen. Eine Umgebungsvariable gilt nur in der aktuellen Shell.

**4. `tofu init`.** Die Lock-Datei war im Repository bereits vorhanden. `init` lädt deshalb genau die dort festgelegten Provider-Versionen, nicht die neuesten.

**5. Plan auf Kostentreiber lesen.** NAT Gateway, ALB, ECS-Service und CloudFront laufen ab dem Anlegen pro Stunde. Ab `apply` lief also die Kostenuhr.

**6. `apply`.** Die generierten Zugangsdaten liefert `tofu output admin_login`. In der Sammelausgabe von `tofu output` stehen sie nur als `<sensitive>`, weil der Output als `sensitive` markiert ist. So landen sie nicht versehentlich in einem geteilten Terminal-Log.

**7. `destroy` in derselben Session.**

## Nachweis des Rückbaus

Ein leerer State beweist nur, dass OpenTofu glaubt, alles gelöscht zu haben. Deshalb habe ich direkt bei AWS nachgefragt:

| Prüfung | Befehl | Ergebnis |
|---|---|---|
| Elastic IPs | `aws ec2 describe-addresses` | leer |
| Load Balancer | `aws elbv2 describe-load-balancers` | leer |
| EFS | `aws efs describe-file-systems` | leer |
| ECS-Cluster | `aws ecs list-clusters` | leer |
| CloudFront | `aws cloudfront list-distributions` | leer |
| VPCs ohne Default | `aws ec2 describe-vpcs --query 'Vpcs[?IsDefault==\`false\`]'` | leer |
| Log Groups | `aws logs describe-log-groups` | leer |
| EC2-Instanzen | `aws ec2 describe-instances` | leer |
| EBS-Volumes | `aws ec2 describe-volumes` | leer |

Besonders kritisch sind zwei Punkte. Eine nicht zugeordnete Elastic IP kostet gerade dann Geld, wenn sie nicht benutzt wird. Eine CloudFront-Distribution braucht zum Löschen zwei Schritte, und wenn der Vorgang abbricht, bleibt sie gern stehen.
## Was ich am Stack verbessern würde

- **Image-Version festlegen:** `copyparty/ac:latest` ist nicht reproduzierbar. Ein `apply` heute und eines in vier Wochen können unterschiedliche Software ausrollen.
- **Tags erweitern:** Bisher gibt es nur `Name`. `Project`, `Owner` und `Environment` würden die Zuordnung im Cost Explorer ermöglichen.
- **Zufallszusatz am Namen:** Damit kollidieren mehrere Deployments im selben Konto nicht.
