# Infrastructure as Code-workshop med Rett i prod 🚀

Denne workshopen gir en intro til infrastructure as code (IaC) med [terraform](https://www.terraform.io/). Se slides i [docs](/docs).

**NB:** Per nå har workshopen en antagelse om at du jobber i Bekk, men dette kan refaktoreres ut i fremtiden.

## Før du starter

1. Installér `az` og `terraform`, f.eks. ved hjelp av [brew](https://brew.sh/): `brew install azure-cli terraform`. Sjekk at terraform versjonen din er minst `v1.0.0` ved å kjøre `terraform version`.

1. Det kan være lurt å installere en plugin i editoren din. VS Code har f.eks. extensionen "Hashicorp Terraform". Alternativt bruke et JetBrains IDE som IntelliJ med pluginen "HashiCorp Terraform / HCL language support".

1. Skriv `az login` i terminalen for å logge inn i Azure. Her skal du logge inn med din Bekk-konto. Når det er gjort kan du bruke `az account show` til å sjekke at du er logget på, og at du bruker Nettskyprogrammet-subscriptionen.

1. Klon repoet med git

Du er nå klar til å starte!

## Terraform

Dette repoet har tre mapper: `frontend/`, `backend/` og `infrastructure/`. De to første inneholder koden for hhv. frontenden og backenden, og er med slik at du kan deploye en full app som faktisk fungerer. `infrastructure/` er den mappen som inneholder terraform-koden, og alle kommandoer og nye filer du lager skal ligge i denne mappen, men mindre noe annet er spesifisert.

I `infrastructure/`-mappen er det foreløpig ikke så mye:

* I `terraform.tf` beskrives hvilke *providers* du trenger, og konfigurasjonen av disse. En provider kan sammenliknes med et bibliotek/*library* fra andre programmeringsspråk. `azurerm` er en slik provider, som definerer ressurser i Azure du kan bruke og oversetter til riktige API-kall når du kjører koden.

* `main.tf` inneholder noen konstanter i `locals`-blokken, som kan brukes i programmet. Merk at `locals` kan defineres i en hvilken som helst terraform-fil, og være globalt tilgjengelige i alle andre filer. `main.tf` inneholder også en definisjon av ressursgruppen som skal opprettes.

* `variables.tf` inneholder variable som gis til terraform. `variable` likner litt på `locals`, men disse kan spesifiseres og overskrives når terraform kjøres, f.eks. ved å gi et ekstra argument på kommandolinjen. Det er litt tungvint å spesifisere variable på kommandolinjen, så vi kommer tilbake til hvordan vi kan gjøre dette enklere. `location` er den eneste variabelen som er definert foreløpig, og den har fått en default-verdi, så det er ikke noe vi trenger å gjøre noe med foreløpig.

* `hacks/`-mappen og `frontend-hacks.tf` inneholder et par skript og litt kode som brukes for å deploye frontenden når den endrer seg. Disse trenger du foreløpig ikke å tenke så mye på, vi kommer tilbake til dem senere.

Det var mye tekst, la oss gå videre til godsakene!

1. Før du kan provisjonere infrastruktur med terraform, må du initialisere providerne som er spesifisert i `terraform.tf`. Dette kan du gjøre ved å kjøre `terraform init` (husk å kjøre den fra `infrastructure/`-mappen!). Dette gjør ingen endringer på infrastrukturen, men oppretter bl.a. `.terraform`-mappen. `terraform init` må kjøres på nytt om du ønsker å installere eller oppgradere providers. **NB!** `.terraform` må ikke committes til git, da den kan inneholde sensitiv informasjon.

1. Når terraform er initialisert kan vi provisjonere infrastruktur ved å kjøre `terraform apply`. Først vil terraform gi en oversikt over endringene som blir gjort. Her opprettes en ressursgruppe i Azure og en random string, `id`, som brukes for å automatisk gi unike navn på ressursene vi skal opprette, f.eks. ressursgruppen. Skriv `yes` når terraform spør om du er sikker på om du vil fortsette.

1. Dersom alt gikk fint kan du finne navnet på ressursgruppen i en av de siste linjene i outputen:

    ```output
    azurerm_resource_group.rg: Creation complete after 1s [id=/subscriptions/9539bc24-8692-4fe2-871e-3733e84b1b73/resourceGroups/iac-workshop-xxxxxxxx]
    ```

    Det er den siste delen (`iac-workshop-xxxxxxxx`) vi er interessert i. Dette er navnet på ressursgruppen, og `xxxxxxxx` vil være den tilfeldige strengen som ble generert.

1. Gå til [Azure-portalen](https://portal.azure.com/), og sjekk at du kan finne ressursgruppen din. Den skal (foreløpig) være tom.

## Backend

Backend-koden bygget til et Docker-image, som lastes opp i GitHub package registry. Vi skal nå sette opp en Azure Container Group som laster ned imaget og kjører det som en container.

1. Opprett en ny fil `backend.tf` i `infrastructure/`.
1. Opprett en `locals` blokk i `backend.tf` med følgende innhold:

    ```terraform
    locals {
      server_port = "8080"
      mgmt_port   = "8090"
    }
    ```

   Her opprettes to konstanter `server_port` og `mgmt_port`, som vi kan referere til senere, f.eks. ved å skrive `local.server_port`. Verdiene som er gitt er ikke tilfeldige, og samsvarer med det som står i `backend/src/main/resources/application.properties`.

1. Vi trenger også en ny variabel, `backend_image` i `variables.tf`. Den kan defineres slik:

    ```terraform
    variable "backend_image" {
      type        = string
      description = "The Docker image to run for the backend"
    }
    ```

    Her deklareres en variabel, `backend_image`, og den må være av typen `string`. Vi kan referere til denne variablen ved å skrive `var.backend_image`.

1. Dersom du nå kjører `terraform apply` vil du bli bedt om å oppgi variabelen. Den vil være `ghcr.io/bekk/iac-workshop-backend:latest`.

1. Vi trenger ikke oppgi variabelen hver gang, for vi kan nemlig putte den i en egen fil som leses automatisk av terraform. Opprett en ny fil `variables.auto.tfvars` med linjen:

    ```terraform
    backend_image = "ghcr.io/bekk/iac-workshop-backend:latest"
    ```

    Dersom du nå kjører `terraform apply` på nytt vil du ikke lenger trenge å skrive inn variabelen.

1. Videre skal vi generere en tilfeldig streng som applikasjonen trenger for å generere JWT-tokens. Det kan vi gjøre slik:

    ```terraform
    resource "random_password" "jwt-secret" {
      length  = 64
      special = false
      lower   = true
      upper   = true
      number  = true
    }
    ```

    Denne strengen kan vi senere bruke ved å referere til `random_password.jwt-secret.result`.

1. Til sist må vi opprette en Azure Container Group som faktisk oppretter backenden:

    ```terraform
    resource "azurerm_container_group" "backend" {
      resource_group_name = azurerm_resource_group.rg.name
      location            = azurerm_resource_group.rg.location
      name                = "${local.resource_prefix}backend"
      ip_address_type     = "public"
      dns_name_label      = local.unique_id_raw
      os_type             = "Linux"

      container {
        name   = "backend"
        image  = var.backend_image
        cpu    = "1"
        memory = "1"

        ports {
          port     = local.server_port
          protocol = "TCP"
        }

        secure_environment_variables = {
          "JWT_SECRET" = random_password.jwt-secret.result
        }

        readiness_probe {
          http_get {
            path   = "/actuator/health"
            port   = local.mgmt_port
            scheme = "Http"
          }
        }
      }
    }
    ```

    Det var en del kode! La oss brekke det opp litt, og se på det viktigste:

    * Vi oppretter her en ressurs av typen `azurerm_container_group`, og kaller denne ressursen for `backend` i første linje. Merk at `backend` er kun et internt navn i terraform, og ikke navnet ressursen får i Azure! Det gjør at vi senere kan referere til ressursen med `azurerm_container_group.backend`.

    * Videre gir vi en del argumenter til ressursblokken. F.eks. setter vi `resource_group_name` og `location` til å tilsvare ressursgruppen som ble opprettet i `main.tf`. `name` settes ved å konkatenere konstanten `local.resource_prefix` (også fra `main.tf`) med strengen `backend`, slik at ressursnavnet i Azure blir `iac-workshop-backend`.

    * `container`-blokken er veldig lik en container-definisjon i Kubernetes (selv om syntaksen er ulik). Merk spesielt at vi setter `image` til variabelen vi definerte i et tidligere steg. Azure vil laste ned imaget for oss (gitt at imaget er åpent tilgjengelig) og kjøre det. `ports`-blokken definerer hvilken port applikasjonen skal være tilgjengelig på. `readiness_probe`-blokken definerer et endepunkt som kan brukes til å sjekke at applikasjonen kjører som den skal, akkurat som i Kubernetes.

1. Nå skal vi ha det som trengs for å provisjonere opp backenden med `terraform apply`. Dette vil ta litt tid første gangen det gjøres. Sjekk etterpå at du finner en ressurs av typen "Container instances" i ressursgruppen din som heter `iac-workshop-backend`.

1. Dersom du klikker på ressursen vil du få en oversikt over noen egenskaper, bl.a. FQDN. Det står for "Fully Qualified Domain Name" og er domenenavnet for backenden. Ettersom applikasjonen kjører på port `8080` må vi legge det på i tillegg for å koble til. Den fulle addressen blir dermed `xxxxxxx.westeurope.azurecontainer.io:8080`, der `xxxxxxxx` fortsatt er den unike id-en generert av terraform. Denne siden vil gi en feilmelding fordi det ikke er et endepunkt definert av applikasjonen der, men om du går til en av applikasjonens definerte endepunkt, f.eks. `xxxxxxxx.westeurope.azurecontainer.io:8080/api/articles` bør du få en JSON-respons for en artikkel med tittel "Hello World".

1. Det er litt tungvint å klikke seg gjennom Azure-portalen for å finne domenenavnet til appen, så vi kan definere output i terraform i stedet. Opprett en ny fil `outputs.tf`, med følgende kode:

    ```terraform
    output "backend_url" {
      value = "http://${azurerm_container_group.backend.fqdn}:${local.server_port}"
    }
    ```

    Her lager vi en ny `output`, `backend_url`, som består av `fqdn` på `backend` ressursen, og portnummeret.

1. Kjør `terraform apply` på nytt, og sjekk at du får `backend_url` liknende dette:

    ```output
    Outputs:

    backend_url = "http://xxxxxxxx.westeurope.azurecontainer.io:8080"
    ```

Det var backenden! Dersom du nå får en god respons fra `http://xxxxxxxx.westeurope.azurecontainer.io:8080/api/articles` og `backend_url` som output kan du gå videre til frontenden.

## Frontend

Frontenden blir bygd av en GitHub Action, som lager en zip-fil som en GitHub-release. Zip-filen skal bli lastet ned, pakket ut og deretter lastet opp til en Azure Storage Account som skal fungere som en nettside med statiske filer.

Først skal vi opprette en Azure Storage Account:

1. Opprett en ny fil, `frontend.tf`, og legg til følgende kode:

    ```terraform
    resource "azurerm_storage_account" "web" {
      name                      = local.unique_id_sanitized
      resource_group_name       = azurerm_resource_group.rg.name
      location                  = azurerm_resource_group.rg.location
      account_tier              = "Standard"
      account_replication_type  = "LRS"
      allow_blob_public_access  = true
      enable_https_traffic_only = false
      min_tls_version           = "TLS1_2"
    }
    ```

    Her skjer det igjen litt forskjellig:

    * Vi har opprettet en ressurs av typen `azurerm_storage_account` som har (det interne) navnet `web`.

    * `name` er satt til `local.unique_id_sanitized`, som er definert i `main.tf`. Navnet på en storage account må være globalt unikt, dvs. ingen storage accounts i Azure kan ha det samme navnet, dermed må vi ha et navn som inneholder en unik id som reduserer sjansen for at noen andre har samme navn.

    * `allow_blob_public_access` er verdt å merke seg. Denne tillater at hvem som helst kan få tilgang til filer i blobs i storage accounten, så lenge de kjenner URL-en. Normalt vil denne settes til `false`, men her ønsker vi at andre kan få tilgang og setter den til `true`, slik at vi kan bruke den til å statiske filer for en allment tilgjengelig nettside.

    * `enable_https_traffic_only` er vanligvis lurt å sette til `true`, men i denne workshopen skal vi ikke sette opp sertifikater, så da må vi nøye oss med `http`.

1. Kjør `terraform apply`. Når storage accounten er opprettet kan du sjekke i ressursgruppen din at du finner en ressurs av typen "Storage account" med navn `iacworkshopxxxxxxxx`.

1. For å bruke storage accounten til en server for statiske filer må vi skru på "static website" featuren. For å få til det må vi legge til en ny `static_website`-blokk inni `azurerm_storage_account`-blokken:

    ```terraform
    resource "azurerm_storage_account" "web" {
      // Samme argumenter som i forrige kodeblokk

      static_website {
        index_document = "index.html"
      }
    }
    ```

    Hva skjer her?

    * Ved å legge til `static_website`-blokken vil det opprettes en *storage account container* som vi kan legge filer i. Dette er ikke det samme som en Kubernetes container. En storage account container er en gruppering av *blobs*, og en blob er en fil som kan være på et hvilket som helst format, f.eks. tekst eller bilder. Denne storage account containeren vil hete `$web`.

    * `index_document`-argumentet spesifiserer navnet på filen som brukes til når det kommer en request til rot-URL-en.

1. Kjør `terraform apply`. Gå så til Azure-portalen, klikk deg inn på storage containeren og klikk på "Containers" i menyen til venstre.

1. Hva blir så URL-en til denne storage accounten? La oss lage en ny `output` i `outputs.tf`:

    ```terraform
    output "storage_account_web_url" {
      value = azurerm_storage_account.web.primary_web_endpoint
    }
    ```

    Her lager vi en ny `output`, som referer til `azurerm_storage_account.web` som vi nettopp opprettet. URL-en er definert i `primary_web_endpoint`.

    Du bør da få en URL i outputen som likner på dette: `https://iacworkshopxxxxxxxx.z6.web.core.windows.net`.

    Dersom du går dit vil du få feilmeldingen "The requested content does not exist.". Hvorfor det? Vi har jo ikke lastet opp noen filer enda! Mer om det straks!

I dette steget har vi opprettet en ny storage account, med en storage account container `$web`. Dersom du har klart å få en URL som `storage_account_web_url`-output og får en feilmelding når du går til URL-en i nettleseren er du klar til neste steg.

## Frontend deploy

Vi deploye de statiske filene for frontenden i storage account containeren `$web`. Her har vi skrevet en del kode for å hjelpe deg. Denne koden finner du i `frontend-hacks.tf` og scriptene i `infrastructure/hacks/`.

1. Først lag en ny variabel `frontend_zip` i `variables.tf`:

    ```terraform
    variable "frontend_zip" {
      type        = string
      description = "URL to ZIP containing the compiled frontend"
    }
    ```

1. Vi kan legge til enda en linje i `variables.auto.tfvars` med URL-en til GitHub-releasen:

    ```terraform
    frontend_zip  = "https://github.com/bekk/iac-workshop/releases/latest/download/iac-workshop-frontend.zip"
    ```

1. I `frontend-hacks.tf` har vi kommentert ut litt kode. Fjern linjene som starter med `/*` og `*/`. Kjør så `terraform apply`.

1. Dersom alt går fint, skal du nå se en nettside dersom du navigerer til URL-en for storage accounten (`storage_account_web_url` output-variabelen).

Dersom nettsiden fungerer er du ferdig med dette steget.

Terraform er ikke nødvendigvis den beste måten å deploye kode på, men vi har tatt det med her for å vise at det er mulig. Som filnavnene tilsier er dette en slags "hack" og du bør tenke deg godt om før du bruker dette til en viktig app i produksjon. Dersom du er interessert i å finne ut av hvordan dette fungerer kan du se på ekstra-oppgavene som kommer til slutt.

## DNS

Til slutt skal vi sette opp et eget domene for appen. Denne gangen har vi satt opp domenet `rettiprod.live` og appen din skal få et subdomene på `xxxxxxxx.rettiprod.live`.

1. Opprett filen `dns.tf`. Og legg til følgende kode:

    ```terraform
    locals {
      assumed_storage_account_web_host = "${local.unique_id_sanitized}.z6.web.core.windows.net"
    }
    ```

    Her lager vi en ny `locals`-blokk som definerer konstanten `assumed_storage_account_web_host`.

1. Videre har vi lagd satt opp de nødvendige, delte ressursene for domenet `rettiprod.live` i ressursgruppen `rett-i-prod-admin`. Vi må referere til disse ressursene for å lage et subdomene. Det gjør vi ved å opprette følgende `data`-blokk:

    ```terraform
    data "azurerm_dns_zone" "rettiprod_live" {
      name                = "rettiprod.live"
      resource_group_name = "rett-i-prod-admin"
    }
    ```

1. Til slutt må vi lage subdomenet. Det gjør vi ved å opprette en CNAME record, som peker fra navnet på subdomenet til URL-en til storage accounten. Det kan vi gjøre slik:

    ```terraform
    resource "azurerm_dns_cname_record" "www" {
      zone_name           = data.azurerm_dns_zone.rettiprod_live.name
      resource_group_name = data.azurerm_dns_zone.rettiprod_live.resource_group_name

      ttl    = 60
      name   = local.unique_id_raw
      record = local.assumed_storage_account_web_host
    }
    ```

    * Legg merke til at `resource_group_name` her blir `rett-i-prod-admin`, og ikke ressursgruppen du tidligere har opprettet. Dette er fordi alle DNS-ressursene må ligge i samme ressursgruppe.

    * `name` her blir navnet på subdomenet, i vårt tilfelle den unike ID-en `xxxxxxxx` som terraform har generert for deg, og `record` er URL-en til den statiske nettsiden i storage accounten.

1. Kjør `terraform apply`. Du kan sjekke at dette ble opprettet riktig ved å gå til `rett-i-prod-admin` ressursgruppen i Azure-portalen. Trykke på ressursen som heter `rettiprod.live` og sjekke at det er opprettet en CNAME record, med samme navn som din unike id (`xxxxxxxx`).

1. Nå må vi oppdatere `azurerm_storage_account` ressursen i `frontend.tf` slik at den aksepterer requests med det nye domenenavnet.

    ```terraform
    resource "azurerm_storage_account" "web" {
        // Argumentene fra tidligere er uforandret

        // Legg til dette:
      custom_domain {
        name          = local.web_hostname
        use_subdomain = false
      }

      depends_on = [
        azurerm_dns_cname_record.www
      ]
    }
    ```

    Her skjer det to ting:

    * Vi legger det nye domenet i `custom_domain`-blokken.

    * Vi sier at storage accounten er avhengig av DNS recorden som ble opprettet tidligere. Dette er fordi DNS recorden må bli opprettet først for at dette skal fungere.

1. Lag en ny output-variabel i `outputs.tf` som gir oss det nye domenenavnet:

    ```terraform
    output "frontend_url" {
      value = "http://${local.web_hostname}"
    }
    ```

1. Kjør `terraform apply` og gå til URL-en du får i output.

Dersom den nye URL-en fungerer, er du ferdig. Bra jobba! 👏

## Ekstra

Du har nå fått hobbyprosjeketet ditt ut i prod! 🚀 Hvis du har tid til overs så har vi noen ekstraoppgaver du kan prøve deg på. Du kan selv velge hvilke du vil gjøre, de er ikke i en spesiell rekkefølge.

* **Slett ressursene du har opprettet:** Dersom du ønsker å slette alle ressursene kan du kjøre `terraform destroy`. Dette vil fjerne alle ressursene i Azure, og nullstille terraform-tilstanden. Dersom du ønsker å opprette ressursene på nytt kan du kjøre `terraform apply` igjen, og alle ressursene vil opprettes på nytt.

    Merk at ettersom all tilstanden slettes av `terraform destroy`, vil den unike id-en bli generert på nytt av terraform. Dermed blir også ressursgruppenavnet og URL-ene nye.

    **NB!** `terraform destroy` vil ugjenopprettelig slette data som ikke er definert av terraform. F.eks. data i databaser, hemmeligheter i key vaults eller brukeropplastede filer i en storage account. I denne workshopen er det trygt, men vær forsiktig om du bruker terraform til faktiske applikasjoner.

* **Les om terraform-provideren for Azure:** Her kan du slå opp de ulike ressursene vi har brukt, og prøve å finne forklaringen på ressursblokker eller argumenter du ikke forstår. Dokumentasjonen finner du [her](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs).

* **Finn ut hvordan frontend-hackene fungerer:** For å deploye frontend-filene har vi lagd et par script i `infrastructure/hacks/`, samt `frontend-hacks.tf`. Disse filene er godt kommentert for å forklare hva som foregår. I tillegg kan terraform-dokumentasjonen for providerne [external](https://registry.terraform.io/providers/hashicorp/external/latest/docs) og [null_resource i null-provideren](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) som begge brukes her.

* **Sett opp en database:**
  Backenden støtter følgende databaser: H2, MSSQL, MySQL og PostgreSQL. Som standard [benyttes H2](./backend/src/main/resources/application.properties) (in-memory database). Finn ut hvordan man konfigurerer en alternativ database via miljøvariabler, samt hvordan man provisjonerer en med Terraform (f.eks. [`azurerm_postgresql_server`](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/postgresql_server). 

### Gjøre endringer på applikasjonene
1. Lag en fork av dette repoet (bruk knappen øverst til høyre), og lag en fork som ligger under din egen bruker. URL-en til det nye repoet blir da `https://github.com/<ditt-github-brukernavn>/iac-workshop`.

1. Gå til din fork av dette repoet. Her må du gjøre noen instillinger:
   1. Gå til `Actions` i menyen. Her skal du skru på GitHub Actions for ditt repo, slik at du får automatiserte bygg av frontend og backend. Byggene (GitHub kaller dette "workflows") vil bare kjøre dersom det er gjort endringer i hhv. `frontend/` eller `backend/` mappene i repoet.
   1. Når automatiserte bygg er skrudd på, må vi kjøre dem manuelt første gang. For hvert av byggene, trykk på "Run workflow" for å kjøre koden. Du trenger ikke laste ned artifaktene som lages av bygget, det gjøres automatisk når koden kjøres.
   1. Når frontend-bygget er ferdig, kan du se at artifakten er lastet opp på `https://github.com/<ditt-github-brukernavn>/iac-workshop/releases`.
   1. Backend-bygget legges i ditt private image-registry. Det bygde Docker-imaget kan du finne på `https://github.com/<ditt-github-brukernavn>?tab=packages>`.
