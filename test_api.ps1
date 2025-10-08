# Script di test per l'API Football
$apiKey = "239a1e02def2d210a0829a958348c5f5"
$apiHost = "v3.football.api-sports.io"

Write-Host "=== TEST API FOOTBALL ===" -ForegroundColor Green

# Ottieni la data di oggi nel formato YYYY-MM-DD
$today = Get-Date -Format "yyyy-MM-dd"
Write-Host "Data di oggi: $today" -ForegroundColor Cyan

# Costruisci l'URL per le partite di oggi
$url = "https://v3.football.api-sports.io/fixtures?date=$today"
Write-Host "URL richiesta: $url" -ForegroundColor Cyan

# Imposta gli headers per la richiesta
$headers = @{
    "x-apisports-key" = $apiKey
}

Write-Host "Invio richiesta API..." -ForegroundColor Yellow
Write-Host "Tentativo di utilizzo della chiave API autorizzata..." -ForegroundColor Yellow

try {
    # Tentiamo di chiamare l'API reale con la chiave autorizzata
    $response = Invoke-RestMethod -Uri $url -Headers $headers -Method GET
    
    # Se arriviamo qui, la chiamata API è riuscita
    Write-Host "Richiesta API completata con successo!" -ForegroundColor Green
    
    # Verifica se ci sono partite
    $fixtures = $response.response
    $fixtureCount = $fixtures.Count
    
    Write-Host "Partite trovate oggi: $fixtureCount" -ForegroundColor Green
    
    # Se non ci sono partite, utilizziamo dati di esempio
    if ($fixtureCount -eq 0) {
        Write-Host "Nessuna partita trovata oggi. Utilizzo dati di esempio..." -ForegroundColor Yellow
        
        # Dati di esempio
        $fixtures = @(
            @{
                fixture = @{
                    id = 1001
                    status = @{
                        long = "In Play"
                        elapsed = 8
                    }
                }
                teams = @{
                    home = @{ name = "Real Madrid" }
                    away = @{ name = "Barcelona" }
                }
                goals = @{
                    home = 0
                    away = 0
                }
            },
            @{
                fixture = @{
                    id = 1002
                    status = @{
                        long = "In Play"
                        elapsed = 12
                    }
                }
                teams = @{
                    home = @{ name = "Manchester United" }
                    away = @{ name = "Liverpool" }
                }
                goals = @{
                    home = 1
                    away = 0
                }
            },
            @{
                fixture = @{
                    id = 1003
                    status = @{
                        long = "In Play"
                        elapsed = 5
                    }
                }
                teams = @{
                    home = @{ name = "Bayern Munich" }
                    away = @{ name = "Borussia Dortmund" }
                }
                goals = @{
                    home = 0
                    away = 0
                }
            },
            @{
                fixture = @{
                    id = 1004
                    status = @{
                        long = "In Play"
                        elapsed = 9
                    }
                }
                teams = @{
                    home = @{ name = "Juventus" }
                    away = @{ name = "AC Milan" }
                }
                goals = @{
                    home = 0
                    away = 0
                }
            },
            @{
                fixture = @{
                    id = 1005
                    status = @{
                        long = "Not Started"
                        elapsed = $null
                    }
                }
                teams = @{
                    home = @{ name = "PSG" }
                    away = @{ name = "Marseille" }
                }
                goals = @{
                    home = $null
                    away = $null
                }
            }
        )
        
        # Aggiorna il conteggio delle partite
        $fixtureCount = $fixtures.Count
    }
    
    # Mostra le prime 5 partite (o meno se ce ne sono meno di 5)
    $limit = [Math]::Min(5, $fixtureCount)
    Write-Host "`nPrime $limit partite di oggi:" -ForegroundColor Cyan
    
    for ($i = 0; $i -lt $limit; $i++) {
        $fixture = $fixtures[$i]
        $fixtureId = $fixture.fixture.id
        $teamHome = $fixture.teams.home.name
        $teamAway = $fixture.teams.away.name
        $fixtureStatus = $fixture.fixture.status.long
        $fixtureElapsed = $fixture.fixture.status.elapsed
        $fixtureGoalsHome = if ($fixture.goals.home -eq $null) { 0 } else { $fixture.goals.home }
        $fixtureGoalsAway = if ($fixture.goals.away -eq $null) { 0 } else { $fixture.goals.away }
        
        Write-Host "ID: $fixtureId | $teamHome - $teamAway | Stato: $fixtureStatus | Minuto: $fixtureElapsed | Risultato: $fixtureGoalsHome-$fixtureGoalsAway" -ForegroundColor White
    }
    
    # Seleziona le prime 3 partite per il monitoraggio
    $selectedIds = @()
    for ($i = 0; $i -lt [Math]::Min(3, $fixtureCount); $i++) {
        $selectedIds += $fixtures[$i].fixture.id
    }
    
    Write-Host "`nPartite selezionate per il monitoraggio: $selectedIds" -ForegroundColor Yellow
    
    # Simula il monitoraggio
    Write-Host "`n=== SIMULAZIONE MONITORAGGIO ===" -ForegroundColor Green
    Write-Host "Monitoraggio avviato per le partite selezionate" -ForegroundColor Yellow
    
    # Controlla le partite selezionate
    $idsString = $selectedIds -join "-"
    $monitorUrl = "https://v3.football.api-sports.io/fixtures?ids=$idsString"
    
    Write-Host "URL monitoraggio: $monitorUrl" -ForegroundColor Cyan
    
    try {
        # Tentiamo di chiamare l'API per il monitoraggio
        $monitorResponse = Invoke-RestMethod -Uri $monitorUrl -Headers $headers -Method GET
        $monitorFixtures = $monitorResponse.response
        Write-Host "Richiesta di monitoraggio completata con successo!" -ForegroundColor Green
    } catch {
        Write-Host "Errore durante la richiesta di monitoraggio. Utilizzo dati di esempio..." -ForegroundColor Yellow
        # Filtra le partite di esempio in base agli ID selezionati
        $monitorFixtures = $fixtures | Where-Object { $selectedIds -contains $_.fixture.id }
    }
    
    Write-Host "Partite recuperate per il monitoraggio: $($monitorFixtures.Count)" -ForegroundColor Green
    
    foreach ($fixture in $monitorFixtures) {
        $fixtureId = $fixture.fixture.id
        $teamHome = $fixture.teams.home.name
        $teamAway = $fixture.teams.away.name
        $fixtureStatus = $fixture.fixture.status.long
        $fixtureElapsed = $fixture.fixture.status.elapsed
        $fixtureGoalsHome = if ($fixture.goals.home -eq $null) { 0 } else { $fixture.goals.home }
        $fixtureGoalsAway = if ($fixture.goals.away -eq $null) { 0 } else { $fixture.goals.away }
        
        Write-Host "PARTITA LIVE: $teamHome - $teamAway | Stato: $fixtureStatus | Minuto: $fixtureElapsed | Risultato: $fixtureGoalsHome-$fixtureGoalsAway" -ForegroundColor White
        
        # Controlla se la partita è 0-0 dopo 8 minuti
        $isZeroZero = ($fixtureGoalsHome -eq 0) -and ($fixtureGoalsAway -eq 0)
        if ($isZeroZero -and $fixtureElapsed -ge 8) {
            Write-Host "CONDIZIONE SODDISFATTA! Invio notifica per: $teamHome - $teamAway" -ForegroundColor Magenta
            Write-Host "NOTIFICA: $teamHome - $teamAway | Ancora 0-0 al minuto $fixtureElapsed? Over 2.5" -ForegroundColor Magenta
        } else {
            Write-Host "Condizione non soddisfatta: isZeroZero=$isZeroZero, elapsed=$fixtureElapsed" -ForegroundColor Gray
        }
    }
    
} catch {
    Write-Host "Errore durante la richiesta API: $_" -ForegroundColor Red
    
    if ($_.Exception.Response) {
        Write-Host "StatusCode: $($_.Exception.Response.StatusCode.value__)" -ForegroundColor Red
        
        try {
            $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
            $reader.BaseStream.Position = 0
            $reader.DiscardBufferedData()
            $responseBody = $reader.ReadToEnd()
            Write-Host "Risposta: $responseBody" -ForegroundColor Red
        } catch {
            Write-Host "Impossibile leggere la risposta di errore" -ForegroundColor Red
        }
    }
    
    Write-Host "Utilizzo dati di esempio..." -ForegroundColor Yellow
    
    # Dati di esempio
    $fixtures = @(
        @{
            fixture = @{
                id = 1001
                status = @{
                    long = "In Play"
                    elapsed = 8
                }
            }
            teams = @{
                home = @{ name = "Real Madrid" }
                away = @{ name = "Barcelona" }
            }
            goals = @{
                home = 0
                away = 0
            }
        },
        @{
            fixture = @{
                id = 1002
                status = @{
                    long = "In Play"
                    elapsed = 12
                }
            }
            teams = @{
                home = @{ name = "Manchester United" }
                away = @{ name = "Liverpool" }
            }
            goals = @{
                home = 1
                away = 0
            }
        },
        @{
            fixture = @{
                id = 1003
                status = @{
                    long = "In Play"
                    elapsed = 5
                }
            }
            teams = @{
                home = @{ name = "Bayern Munich" }
                away = @{ name = "Borussia Dortmund" }
            }
            goals = @{
                home = 0
                away = 0
            }
        },
        @{
            fixture = @{
                id = 1004
                status = @{
                    long = "In Play"
                    elapsed = 9
                }
            }
            teams = @{
                home = @{ name = "Juventus" }
                away = @{ name = "AC Milan" }
            }
            goals = @{
                home = 0
                away = 0
            }
        },
        @{
            fixture = @{
                id = 1005
                status = @{
                    long = "Not Started"
                    elapsed = $null
                }
            }
            teams = @{
                home = @{ name = "PSG" }
                away = @{ name = "Marseille" }
            }
            goals = @{
                home = $null
                away = $null
            }
        }
    )
    
    # Mostra le prime 5 partite (o meno se ce ne sono meno di 5)
    $fixtureCount = $fixtures.Count
    $limit = [Math]::Min(5, $fixtureCount)
    Write-Host "`nPrime $limit partite di esempio:" -ForegroundColor Cyan
    
    for ($i = 0; $i -lt $limit; $i++) {
        $fixture = $fixtures[$i]
        $fixtureId = $fixture.fixture.id
        $teamHome = $fixture.teams.home.name
        $teamAway = $fixture.teams.away.name
        $fixtureStatus = $fixture.fixture.status.long
        $fixtureElapsed = $fixture.fixture.status.elapsed
        $fixtureGoalsHome = if ($fixture.goals.home -eq $null) { 0 } else { $fixture.goals.home }
        $fixtureGoalsAway = if ($fixture.goals.away -eq $null) { 0 } else { $fixture.goals.away }
        
        Write-Host "ID: $fixtureId | $teamHome - $teamAway | Stato: $fixtureStatus | Minuto: $fixtureElapsed | Risultato: $fixtureGoalsHome-$fixtureGoalsAway" -ForegroundColor White
    }
    
    # Seleziona le prime 3 partite per il monitoraggio
    $selectedIds = @()
    for ($i = 0; $i -lt [Math]::Min(3, $fixtureCount); $i++) {
        $selectedIds += $fixtures[$i].fixture.id
    }
    
    Write-Host "`nPartite selezionate per il monitoraggio: $selectedIds" -ForegroundColor Yellow
    
    # Simula il monitoraggio
    Write-Host "`n=== SIMULAZIONE MONITORAGGIO ===" -ForegroundColor Green
    Write-Host "Monitoraggio avviato per le partite selezionate" -ForegroundColor Yellow
    
    # Filtra le partite di esempio in base agli ID selezionati
    $monitorFixtures = $fixtures | Where-Object { $selectedIds -contains $_.fixture.id }
    
    Write-Host "Partite recuperate per il monitoraggio: $($monitorFixtures.Count)" -ForegroundColor Green
    
    foreach ($fixture in $monitorFixtures) {
        $fixtureId = $fixture.fixture.id
        $teamHome = $fixture.teams.home.name
        $teamAway = $fixture.teams.away.name
        $fixtureStatus = $fixture.fixture.status.long
        $fixtureElapsed = $fixture.fixture.status.elapsed
        $fixtureGoalsHome = if ($fixture.goals.home -eq $null) { 0 } else { $fixture.goals.home }
        $fixtureGoalsAway = if ($fixture.goals.away -eq $null) { 0 } else { $fixture.goals.away }
        
        Write-Host "PARTITA LIVE: $teamHome - $teamAway | Stato: $fixtureStatus | Minuto: $fixtureElapsed | Risultato: $fixtureGoalsHome-$fixtureGoalsAway" -ForegroundColor White
        
        # Controlla se la partita è 0-0 dopo 8 minuti
        $isZeroZero = ($fixtureGoalsHome -eq 0) -and ($fixtureGoalsAway -eq 0)
        if ($isZeroZero -and $fixtureElapsed -ge 8) {
            Write-Host "CONDIZIONE SODDISFATTA! Invio notifica per: $teamHome - $teamAway" -ForegroundColor Magenta
            Write-Host "NOTIFICA: $teamHome - $teamAway | Ancora 0-0 al minuto $fixtureElapsed? Over 2.5" -ForegroundColor Magenta
        } else {
            Write-Host "Condizione non soddisfatta: isZeroZero=$isZeroZero, elapsed=$fixtureElapsed" -ForegroundColor Gray
        }
    }
}

Write-Host "`n=== FINE TEST API FOOTBALL ===" -ForegroundColor Green