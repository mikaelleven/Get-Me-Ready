
# Skapa AGENTS.md [COMPLETED]

~~- Skapa en AGENTS.md fil som beskriver de olika agenter som används i GetMeReady~~
~~- Dokumentera att vi har tre olika register, en för varje plattform (Mac, Win, Linux)~~
~~- Varje register har unika plattspecifika sökvägar och metoder för att hitta och installera programvara~~
~~- Alla register är plattformsspecifika och endast kan användas på den plattform den är designad för~~
~~- Alla register använder samma GMR filformat och namnkonventioner/regler~~
~~- Ignorera global MEMORY.md (varken läs eller skriv till den), användt lokala projektfiler som minner istället~~


# Sammanfatta tolkningsregler för GMR filer ("moduler") [COMPLETED]

<del>
Målbild: en överordnad regelfil som beskriver (markdown) hur GMR-filer ("moduler") ska tolkas och användas.

Syfte: Definiera en standardiserad metod för att tolka GMR-filer och använda dem för att automatisera plattformsspecifika konfigurationer.

Todo:
 - Utfrå ifrån reglerna i [@GMR-beta.ps1](file:///D:/OneDrive/Projects/Codex/GetMeReady/GetMyWinReady/GMR-beta.ps1)
 - Analysera existerande GMR-filer i .\GetMyWinReady\*.gmr för att definiera standardiserade kategorier
 - Sammanfatta tolkningsreglerna i RULES.md med tydliga instruktioner och exempel
 - Säkerställ att det finns en särskild regler för att installera one-liner PS script från URL:ar (t.ex. "" och "")
	- Använder pattern: `$> irm <url> | iex`
	- T.ex. om input är "iex (irm https://hermes-agent.nousresearch.com/install.ps1)" blir kommandot `$> irm https://hermes-agent.nousresearch.com/install.ps1 | iex` och om input är "https://herdr.dev/install.ps1" blir kommandot `$> irm https://herdr.dev/install.ps1 | iex`
 - Motsvarande samma regler som för .ps1 script på Win så ska det finns följande regel för .sh script på Mac:
	- Använder pattern: `$> curl -fsSL <url> | bash`
	- T.ex. blir "https://hermes-agent.nousresearch.com/install.sh" kommandot `$> curl -fsSL https://hermes-agent.nousresearch.com/install.sh | bash`
 - Validera sammanfattade tolkningsregler och jämför mot GMR-filer i .\GetMyWinReady\*.gmr i syftet att säkerställa att reglerna fungerar som förväntat
</del>


# Skapa cross-platform "/append" skill [COMPLETED]

<del>
Syfte: lägga till ett program/script i en/alla/flera av våra register (Mac, Win, Linux)

Målbild: utifrån prompt avgöra om programmet ska läggas till i en, flera eller alla tre plattformars registry.

Funktionalitet:
 - Projekt-lokal skill med namnet "/append" (ignorera namnregler)
 - Avgör vilken metod som passar bäst
  - T.ex. använd winget på Win och homebrew på Mac
  - Sök fram bäst matchande paket
  - Fråga användaren om fler detaljer vid behov
- Hitta en lämplig kategori (GMR modul)
  - Antingen explicit genom prompt eller implicit genom att titta på existerande GMR-filer och liknande program
  - Om ingen matchande kategori hittas, skapa en ny GMR kategori
- Lägg till programmet i den/alla/flera register
- För program som kräver flera steg ska ett applikations-specifikt script skapas
  - Använd cmd eller bash
  - Skapa ett script som kan köras från terminalen
   - Ett script i .GMR filen anges i formatet `$> <script filename>`
</del>



# Lägg till program i modulen "Terminal Tools & Tweaks" [COMPLETED]

<del>
Använd skill "/append"

Lägg till:
- "Herdr": "irm https://herdr.dev/install.ps1 | iex", brew install herdr
- "Hermes": iex (irm https://hermes-agent.nousresearch.com/install.ps1), curl -fsSL https://hermes-agent.nousresearch.com/install.sh | bash
</del>


# Skapa basfiler för GetMyMacReady [COMPLETED]

<del>
- Kopiera README.md från GetMyWinReady till GetMyMacReady
  - Uppdatera alla Windows-specifika referenser till macOS
- Flytta update program catalog-scriptet från GetMyWinReady till GetMeReady (root projektet)
  - Scriptet ska ta katalog som input, t.ex. `UpdateProgramCatalog.cmd GetMyWinReady`
  - Scriptet uppdaterar programkatalogen för den angivna katalogen
- Skapa alias UpdateProgramCatalog.cmd i både GetMyWinReady och GetMyMacReady som anropar .ps1 scriptet från root projektet
  - Skicka med aktuellt katalog, t.ex. `..\UpdateProgramCatalog.ps1 ..\GetMyWinReady`
- Kör UpdateProgramCatalog.ps1 från GetMyMacReady, validera att programkatalogen uppdateras korrekt
</del>

# Skapa basfiler för GetMyNixReady [COMPLETED]

~~- Kopiera README.md från GetMyMacReady till GetMyNixReady
  - Uppdatera alla Windows-specifika och Mac-specifica referenser till Linux
- Skapa alias UpdateProgramCatalog.cmd i både GetMyNixReady som anropar .ps1 scriptet från root projektet
  - Skicka med aktuellt katalog, t.ex. `..\UpdateProgramCatalog.ps1 ..\GetMyNixReady`
- Kör UpdateProgramCatalog.ps1 från GetMyNixReady, validera att programkatalogen uppdateras korrekt~~
