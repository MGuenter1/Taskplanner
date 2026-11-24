# Taskplanner

Gemeinsames Aufgaben-Board (Offen / In Arbeit / Fertig) mit Zuständigen, Fälligkeiten, Prioritäten und Kommentaren.
Die ganze App steckt in einer Datei: [`index.html`](index.html). Die Daten liegen zentral in [Supabase](https://supabase.com),
Änderungen erscheinen bei allen sofort.

## Einrichtung

1. **Datenbank:** Im Supabase-Dashboard unter *SQL Editor* den Inhalt von [`supabase/schema.sql`](supabase/schema.sql) einfügen,
   in der letzten Zeile die eigene E-Mail-Adresse eintragen und ausführen. Diese Adresse wird Besitzer des Boards.
2. **Schlüssel:** In `index.html` bei `SUPABASE_KEY` den *anon* bzw. *publishable* Key eintragen
   (Project Settings → API Keys). Niemals den *service_role*/*secret* Key verwenden.
3. **Anmeldelinks:** Unter *Authentication → URL Configuration* die Adresse der Seite als *Site URL* und *Redirect URL* eintragen,
   z. B. `https://mguenter1.github.io/Taskplanner/`.
4. **Veröffentlichen:** Im GitHub-Repo unter *Settings → Pages* den Branch `main` als Quelle wählen.

## Zugriff

- Anmeldung per E-Mail-Link, ohne Passwort.
- Nur eingeladene Adressen sehen das Board. Der Besitzer lädt über „Jemanden einladen“ ein,
  wahlweise mit *Bearbeiten* oder *Nur lesen*, und kann den Zugriff wieder entziehen.
- Die Regeln dafür setzt die Datenbank durch (Row Level Security), nicht der Browser.

Ohne eingetragenen Schlüssel speichert die Seite nur lokal im Browser.
