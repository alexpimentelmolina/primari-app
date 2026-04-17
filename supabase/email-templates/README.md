# Plantillas de email · Prímari

Plantillas HTML y texto plano para los correos transaccionales de Supabase Auth.

## Plantillas disponibles

| Archivo | Descripción | Template en Supabase |
|---|---|---|
| `confirm-signup.html` | Confirmación de cuenta nueva | Confirm signup |
| `confirm-signup.txt` | Versión texto plano | — |

## Cómo aplicar una plantilla

1. Abre el Dashboard de Supabase → **Authentication → Email Templates**
2. Selecciona la plantilla correspondiente
3. Pega el contenido de `.html` en el campo **Body**
4. Guarda

## Variable principal

`{{ .ConfirmationURL }}` — URL de confirmación generada por Supabase. No modificar.

## Requisitos previos

Antes de personalizar el remitente, configurar SMTP personalizado.
Ver instrucciones en el commit `security/email-setup`.
