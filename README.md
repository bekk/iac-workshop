# Infrastructure as Code-workshop med Rett i prod 🚀

Denne workshopen gir en intro til infrastructure as code (IaC) med [terraform](https://www.terraform.io/). Se slides i [docs](/docs).

NB! Denne workshopen krever at enkelte ressurser er satt opp for å bruke egne domenenavn. Dersom du skal gå gjennom workshopen på egenhånd vil ikke alt fungere.

## Før du starter

1. Installér `az` og `terraform`, `npm` og `node`, f.eks. ved hjelp av [brew](https://brew.sh/) om du bruker macOS: `brew install azure-cli terraform node@16`. Sjekk at terraform versjonen din er minst `v1.0.0` ved å kjøre `terraform version`, og at node versjonen er minst `v16.0.0` ved å kjøre `node --version`.

1. Det kan være lurt å installere en plugin i editoren din. VS Code har f.eks. extensionen "Hashicorp Terraform". Alternativt bruke et JetBrains IDE som IntelliJ med pluginen "HashiCorp Terraform / HCL language support".

1. Du skal ha fått en mail fra oss med invitasjon som gir deg tilgang til workshopens Azure tenant. Denne emailen kommer fra `invitations@microsoft.com` og har tittelen "Bekk Terraform Workshop invited you to access applications within their organization". Trykk på "Accept Invitation" og følg stegene for å få tilgang til Azure-portalen (`portal.azure.com`).

1. Når du har kommet til Azure-portalen, sjekk at det står "Bekk Terraform Workshop" øverst til høyre. Dersom det ikke gjør det, trykk på profilbildet ditt (øverst til høyre), deretter "Switch directory" og velg "Bekk Terraform Workshop" på siden du kommer til.

1. Skriv `az login` i terminalen for å logge inn i Azure. Når det er gjort kan du bruke `az account show` til å sjekke at du er logget på, og at du bruker `iac-workshop`-subscriptionen. Dersom det ikke stemmer kan du bruke `az account set -s iac-workshop` for å bytte subscription, verifiser etterpå med `az account show`.

1. Klon repoet med git

Du er nå klar til å starte!

## Terraform

Dette repoet har tre mapper: `frontend/`, `backend/` og `infrastructure/`. De to første inneholder koden for hhv. frontenden og backenden, og er med slik at du kan deploye en full app som faktisk fungerer. `infrastructure/` er den mappen som inneholder terraform-koden, og alle kommandoer og nye filer du lager skal ligge i denne mappen, men mindre noe annet er spesifisert.

I `infrastructure/`-mappen er det foreløpig ikke så mye:

* I `terraform.tf` beskrives hvilke *providers* du trenger, og konfigurasjonen av disse. En provider kan sammenliknes med et bibliotek/*library* fra andre programmeringsspråk. `azurerm` er en slik provider, som definerer ressurser i Azure du kan bruke og oversetter til riktige API-kall når du kjører koden.

* `main.tf` inneholder noen konstanter i `locals`-blokken, som kan brukes i programmet. Merk at `locals` kan defineres i en hvilken som helst terraform-fil, og være globalt tilgjengelige i alle andre filer. `main.tf` inneholder også en definisjon av ressursgruppen som skal opprettes.

* `variables.tf` inneholder variable som gis til terraform. `variable` likner litt på `locals`, men disse kan spesifiseres og overskrives når terraform kjøres, f.eks. ved å gi et ekstra argument på kommandolinjen. Det er litt tungvint å spesifisere variable på kommandolinjen, så vi kommer tilbake til hvordan vi kan gjøre dette enklere. `location` er den eneste variabelen som er definert foreløpig, og den har fått en default-verdi, så det er ikke noe vi trenger å gjøre noe med foreløpig.

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

1. Vi trenger også en ny variabel, `backend_image`, i `variables.tf`. Den kan defineres slik:

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
      ip_address_type     = "Public"
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

Vi skal bruke Azure Blob Storage til å hoste statiske filer frontend-filer. Forenklet sett skal vi bruke en Azure Storage Account som en tradisjonell webserver.

Først skal vi opprette en ny storage account:

1. Opprett en ny fil, `frontend.tf`, og legg til følgende kode og erstatt `<ressursgruppenavn>` og `<ressursgrupperegion>` med riktige verdier ved å bruke ressursgruppe-ressursen som er opprettet tidligere. (Hint: hvordan er dette gjort for andre ressurser vi har allerede har opprettet?)

    ```terraform
    resource "azurerm_storage_account" "web" {
      name                             = local.unique_id_sanitized
      resource_group_name              = <ressursgruppenavn>
      location                         = <ressursgrupperegion>
      account_tier                     = "Standard"
      account_replication_type         = "LRS"
      allow_nested_items_to_be_public  = true
      enable_https_traffic_only        = false
      min_tls_version                  = "TLS1_2"
    }
    ```

    Her skjer det igjen litt forskjellig:

    * Vi har opprettet en ressurs av typen `azurerm_storage_account` som har (det interne) navnet `web`.

    * `name` er satt til `local.unique_id_sanitized`, som er definert i `main.tf`. Navnet på en storage account må være globalt unikt, dvs. ingen storage accounts i Azure kan ha det samme navnet, dermed må vi ha et navn som inneholder en unik id som reduserer sjansen for at noen andre har samme navn.

    * `allow_nested_items_to_be_public` er verdt å merke seg. Denne tillater at hvem som helst kan få tilgang til blobs (filer) i storage accounten, så lenge de kjenner URL-en. Normalt vil det være lurt å sette denne `false`, men her ønsker vi at andre kan få tilgang og setter den til `true`, slik at vi kan bruke den til å statiske filer for en allment tilgjengelig nettside.

    * `enable_https_traffic_only` er vanligvis lurt å sette til `true`, men foreløpig skal vi ikke sette opp HTTPS (det kan du gjøre i ekstraoppgavene på slutten).

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

For at brukere skal kunne se og lage poster i Bekkium må frontenden opp. Vi skal her bygge filene manuelt lokalt først (tilsvarende byggsteget i en CI/CD pipeline), og bruke terraform til å laste disse opp i storage accounten.

For å kunne nå de statiske i nettleseren, må vi deploye filene i storage account containeren `$web`.

1. For å rette frontenden til riktig backend må du sette miljøvariabelen `REACT_APP_BACKEND_URL` for bygget. Denne må være outputen `backend_url` som du får når du kjører `terraform apply` (den skal se ut omtrent som `http://xxxxxxxx.westeurope.azurecontainer.io:8080`), pluss `/api` som postfiks. Kommandoen du må kjøre fra `frontend/`-mappen blir dermed omtrent slik:

    ```sh
    # Bash (macOS/Linux/WSL)
    npm ci && REACT_APP_BACKEND_URL="http://xxxxxxxx.westeurope.azurecontainer.io:8080/api" npm build
    # Powershell 7 (Windows)
    $env:REACT_APP_BACKEND_URL="http://xxxxxxxx.westeurope.azurecontainer.io:8080/api"
    npm ci
    npm build
    ```

    Dersom alt gikk bra ligger nå den ferdigbygde frontenden i `frontend/build/`-mappen, klar for bruk i senere steg.

1. For å hjelpe deg litt på vei har vi definert noen lokale variable some blir nyttige, disse kan puttes på toppen av `frontend.tf`.

    ```terraform
    locals {
      frontend_dir   = "${path.module}/../frontend"
      frontend_files = fileset(local.frontend_dir, "**")
      frontend_src = {
        for fn in local.frontend_files :
        fn => filemd5("${local.frontend_dir}/${fn}") if(length(regexall("(node_modules/.*)|build/.*", fn)) == 0)
      }

      mime_types = {
        ".gif"  = "image/gif"
        ".html" = "text/html"
        ".ico"  = "image/vnd.microsoft.icon"
        ".jpeg" = "image/jpeg"
        ".jpg"  = "image/jpeg"
        ".js"   = "text/javascript"
        ".json" = "application/json"
        ".map"  = "application/json"
        ".png"  = "image/png"
        ".txt"  = "text/plain"
      }
    }
    ```

1. Når frontend-filene er bygget i `frontend/build` er de klare for opplastning. Vi skal nå laste opp hver enkelt fil som en blob til `$web` containeren. Dette er prima use case for [løkker](https://www.terraform.io/docs/language/meta-arguments/for_each.html). For at filene skal tolkes riktig må MIME-typen være rett. Vi har allerede definert de nødvendige typene i `local.mime_types` map-et. Bruk [`lookup`-funksjonen](https://www.terraform.io/docs/language/functions/lookup.html) for å setter `content_type` til riktig MIME-type. (Hint: `regex("\\.[^.]+$", basename(each.value))` gir deg filendingen, og default kan være `null`).

    ```terraform
    resource "azurerm_storage_blob" "payload" {
      // Vi trenger kun ferdige statiske filer
      for_each               = fileset("${local.frontend_dir}/build", "**")
      name                   = each.value
      storage_account_name   = azurerm_storage_account.web.name
      storage_container_name = "$web"
      type                   = "Block"
      source                 = "${local.frontend_dir}/build/${each.value}"
      content_md5            = filemd5("${local.frontend_dir}/build/${each.value}")
      content_type           = <sett inn riktig MIME-type>
    }
    ```

1. Kjør `terraform apply`. Dersom alt går fint, skal du nå se en nettside dersom du navigerer til URL-en for storage accounten (`storage_account_web_url` output-variabelen).

Dersom nettsiden fungerer er du ferdig med dette steget.

Terraform er ikke nødvendigvis den beste måten å deploye kode på, men vi har tatt det med her for å vise at det er _mulig_. I et reelt scenario ville man kanskje ønske å gjøre det på andre måter.

## DNS

Til slutt skal vi sette opp et eget domene for appen. Denne gangen har vi satt opp domenet `rettiprod.live` og appen din skal få et subdomene på `xxxxxxxx.rettiprod.live`.

1. Opprett filen `dns.tf`. Og legg til følgende kode:

    ```terraform
    locals {
      assumed_storage_account_web_host = "${local.unique_id_sanitized}.z6.web.core.windows.net"
    }
    ```

1. Videre har vi lagd satt opp de nødvendige, delte ressursene for domenet `rettiprod.live` i ressursgruppen `workshop-admin`. Vi må referere til disse ressursene for å lage et subdomene. Det gjør vi ved å opprette følgende `data`-blokk:

    ```terraform
    data "azurerm_dns_zone" "rettiprod_live" {
      name                = "rettiprod.live"
      resource_group_name = "workshop-admin"
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

    * Legg merke til at `resource_group_name` her blir `workshop-admin`, og ikke ressursgruppen du tidligere har opprettet. Dette er fordi alle DNS-ressursene må ligge i samme ressursgruppe.

    * `name` her blir navnet på subdomenet, i vårt tilfelle den unike ID-en `xxxxxxxx` som terraform har generert for deg, og `record` er URL-en til den statiske nettsiden i storage accounten.

1. Kjør `terraform apply`. Du kan sjekke at dette ble opprettet riktig ved å gå til `rett-i-prod-admin` ressursgruppen i Azure-portalen. Trykke på ressursen som heter `rettiprod.live` og sjekke at det er opprettet en CNAME record, med samme navn som din unike id (`xxxxxxxx`).

1. Nå må vi oppdatere `azurerm_storage_account` ressursen i `frontend.tf` slik at den aksepterer requests med det nye domenenavnet. Storage accounten må nå provisjoneres opp etter at DNS-recorden er klar, hvis ikke vil det ikke fungere. Det kan vi ordne ved å legge in et [`depends_on`-array](https://www.terraform.io/docs/language/meta-arguments/depends_on.html).

    ```terraform
    resource "azurerm_storage_account" "web" {
        // Argumentene fra tidligere er uforandret

      custom_domain {
        name          = local.web_hostname
        use_subdomain = false
      }

      // Legg til depends_on her.
    }
    ```

1. Lag en ny output-variabel, `frontend_url` som gir oss den nye URL-en til frontenden.

1. Kjør `terraform apply` og gå til URL-en du får i output.

Dersom du får den nye nye URL-en som output (den skal se ca. slik ut: `http://xxxxxxx.rettiprod.live`) og den fungerer, er du ferdig. Bra jobba! 👏

## Ekstra

Du har nå fått hobbyprosjeketet ditt ut i prod! 🚀 Hvis du har tid til overs så har vi noen ekstraoppgaver du kan prøve deg på. Du kan selv velge hvilke du vil gjøre, de fleste er ikke i en spesiell rekkefølge.

### Slett ressursene du har opprettet

Dersom du ønsker å slette alle ressursene kan du kjøre `terraform destroy`. Dette vil fjerne alle ressursene i Azure, og nullstille terraform-tilstanden. Dersom du ønsker å opprette ressursene på nytt kan du kjøre `terraform apply` igjen, og alle ressursene vil opprettes på nytt.

Merk at ettersom all tilstanden slettes av `terraform destroy`, vil den unike id-en bli generert på nytt av terraform. Dermed blir også ressursgruppenavnet og URL-ene nye.

**NB!** `terraform destroy` vil ugjenopprettelig slette data som ikke er definert av terraform. F.eks. data i databaser, hemmeligheter i key vaults eller brukeropplastede filer i en storage account. I denne workshopen er det trygt, men vær forsiktig om du bruker terraform til faktiske applikasjoner.

### Les om terraform-provideren for Azure

Her kan du slå opp de ulike ressursene vi har brukt, og prøve å finne forklaringen på ressursblokker eller argumenter du ikke forstår. Dokumentasjonen finner du [her](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs).

### Sett opp en database

Backenden støtter følgende databaser: H2, MSSQL, MySQL og PostgreSQL. Som standard [benyttes H2](./backend/src/main/resources/application.properties) (in-memory database). Finn ut hvordan man konfigurerer en alternativ database via miljøvariabler, samt hvordan man provisjonerer en med Terraform (f.eks. [`azurerm_postgresql_server`](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/postgresql_server).

### Slå på HTTPS for backend

Det kan være nyttig med HTTPS. Det enkleste er en løsning som håndterer HTTPS sertifikater automatisk for oss, f.eks. ved å spinne opp en ny container i Azure Container Instances som fungerer som en *reverse proxy* og tar seg av dette.

Caddy kan brukes som reverse proxy. Container-imaget `caddy` inneholder alt du trenger, og kjøres ved å bruke kommandoen `caddy reverse-proxy --from <ekstern-aci-url> --to <intern-backend-url>` når containeren skal startes. Du vil også trenge å konfigurere et `volume` for containeren, der Caddy-instansen kan lagre data. Dette gjøres enklest ved å lage en file share i en storage account (`azurerm_storage_share`). Konfigurer port `80` og `433` for containeren.

Oppdatér `backend_url` outputen til å bruke `https` og fjern portspesifikasjonen (den vil da automatisk bruke `443`).

Test at det fungerer ved å sjekke at du får suksessfull respons fra `https://xxxxxxxx.rettiprod.live/api/articles`.

Videre bør man bygge frontenden på nytt (etterfulgt av en ny `terraform apply`), med ny `REACT_APP_BACKEND_URL` til å bruke HTTPS fremfor HTTP for å unngå advarsler om og problemer med [mixed content](https://developer.mozilla.org/en-US/docs/Web/Security/Mixed_content). Kommandoen for å bygge frontenden bør nå se omtrent slik ut:

```sh
npm ci && REACT_APP_BACKEND_URL="https://xxxxxxxx.rettiprod.live/api" npm build
```

Nyttige lenker:

* [Azure Container Instance](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/container_group)
* [Storage Account](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_account) og [file share](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_share)

### Slå på HTTPS for frontend med eget domene

For å gjøre dette steget må HTTPS fungere for backend først. Storage accounten støtter HTTPS ut av boksen med sitt eget domene (typisk `<storage-account-navn>.z6.web.core.windows.net`), men om vi skal ha HTTPS for eget domene blir det komplisert. Det finnes flere måter å gjøre dette på, men her skal vi sette opp en CDN som håndterer sertifikatet for oss. Terraform-dokumentasjonen for [`azurerm_cdn_endpoint_custom_domain`](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cdn_endpoint_custom_domain) har et godt eksempel på hvordan en CDN kan settes opp med eget domene. I tillegg må du bruke underressursen `cdn_managed_https` for å få HTTPS for domenet. Merk at når du skrur på HTTPS vil `terraform apply` kjøre til sertifikater er ferdig provisjonert av Azure - dette kan ta opp mot en time, i denne workshopen anbefaler vi at du gjør dette sist.

Du kan nå også sette `enable_https_traffic_only` til `true` for storage accounten.

### Gjøre endringer på applikasjonene

1. Lag en fork av dette repoet (bruk knappen øverst til høyre), og lag en fork som ligger under din egen bruker. URL-en til det nye repoet blir da `https://github.com/<ditt-github-brukernavn>/iac-workshop`.

1. Gå til din fork av dette repoet. Her må du gjøre noen instillinger:
   1. Gå til `Actions` i menyen. Her skal du skru på GitHub Actions for ditt repo, slik at du får automatiserte bygg av frontend og backend. Byggene (GitHub kaller dette "workflows") vil bare kjøre dersom det er gjort endringer i hhv. `frontend/` eller `backend/` mappene i repoet.
   1. Når automatiserte bygg er skrudd på, må vi kjøre dem manuelt første gang. For hvert av byggene, trykk på "Run workflow" for å kjøre koden. Du trenger ikke laste ned artifaktene som lages av bygget, det gjøres automatisk når koden kjøres.
   1. Når frontend-bygget er ferdig, kan du se at artifakten er lastet opp på `https://github.com/<ditt-github-brukernavn>/iac-workshop/releases`.
   1. Backend-bygget legges i ditt private image-registry. Det bygde Docker-imaget kan du finne på `https://github.com/<ditt-github-brukernavn>?tab=packages>`.
