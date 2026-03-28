# CSS Cleanup Plan (3 Lotes)

Plano gerado a partir de `docs/css_usage_audit.json`.
Objetivo: remover CSS não usado com risco controlado, validando a cada lote.

## Resumo
- Lote 1 (baixo risco): 22 arquivos
- Lote 2 (medio risco): 34 arquivos
- Lote 3 (alto risco): 0 arquivos

## Lote 1 - Baixo Risco
- Criterio: Duplicatas em `app/assets/stylesheets/**` com arquivo equivalente em outro caminho.
- Quantidade: 22

- `app/assets/stylesheets/plugins/Drag-And-Drop/dist/imageuploadify.min.css`
- `app/assets/stylesheets/plugins/apexcharts-bundle/css/apexcharts.css`
- `app/assets/stylesheets/plugins/bootstrap-material-datetimepicker/css/bootstrap-material-datetimepicker.min.css`
- `app/assets/stylesheets/plugins/bs-stepper/css/bs-stepper-custom.css`
- `app/assets/stylesheets/plugins/datatable/css/dataTables.bootstrap5.min.css`
- `app/assets/stylesheets/plugins/datetimepicker/css/classic.css`
- `app/assets/stylesheets/plugins/datetimepicker/css/classic.date.css`
- `app/assets/stylesheets/plugins/datetimepicker/css/classic.time.css`
- `app/assets/stylesheets/plugins/fancy-file-uploader/fancy_fileupload.css`
- `app/assets/stylesheets/plugins/fullcalendar/css/main.css`
- `app/assets/stylesheets/plugins/fullcalendar/css/main.min.css`
- `app/assets/stylesheets/plugins/highcharts/css/dark-unica.css`
- `app/assets/stylesheets/plugins/highcharts/css/grid-light.css`
- `app/assets/stylesheets/plugins/highcharts/css/highcharts-white.css`
- `app/assets/stylesheets/plugins/highcharts/css/highcharts.css`
- `app/assets/stylesheets/plugins/highcharts/css/sand-signika.css`
- `app/assets/stylesheets/plugins/input-tags/css/tagsinput.css`
- `app/assets/stylesheets/plugins/morris/css/morris.css`
- `app/assets/stylesheets/plugins/notifications/css/lobibox.css`
- `app/assets/stylesheets/plugins/notifications/css/lobibox.min.css`
- `app/assets/stylesheets/plugins/select2/css/select2-bootstrap4.css`
- `app/assets/stylesheets/plugins/select2/css/select2.min.css`

Checklist de validacao apos remover este lote:
- Login / logout
- Dashboard app e admin
- Cadastro register e telas de autenticacao
- Formularios de cliente, tecnico, OS e configuracoes
- Tabela de logs e filtros (flatpickr/select2)

## Lote 2 - Medio Risco
- Criterio: Arquivos marcados como `unused_candidate` fora de `app/javascript` (normalmente temas/plugins soltos).
- Quantidade: 34

- `app/assets/plugins/Drag-And-Drop/dist/imageuploadify.min.css`
- `app/assets/plugins/apexcharts-bundle/css/apexcharts.css`
- `app/assets/plugins/bootstrap-material-datetimepicker/css/bootstrap-material-datetimepicker.min.css`
- `app/assets/plugins/bs-stepper/css/bs-stepper-custom.css`
- `app/assets/plugins/datatable/css/dataTables.bootstrap5.min.css`
- `app/assets/plugins/datetimepicker/css/classic.css`
- `app/assets/plugins/datetimepicker/css/classic.date.css`
- `app/assets/plugins/datetimepicker/css/classic.time.css`
- `app/assets/plugins/fancy-file-uploader/fancy_fileupload.css`
- `app/assets/plugins/fullcalendar/css/main.css`
- `app/assets/plugins/fullcalendar/css/main.min.css`
- `app/assets/plugins/highcharts/css/dark-unica.css`
- `app/assets/plugins/highcharts/css/grid-light.css`
- `app/assets/plugins/highcharts/css/highcharts-white.css`
- `app/assets/plugins/highcharts/css/highcharts.css`
- `app/assets/plugins/highcharts/css/sand-signika.css`
- `app/assets/plugins/input-tags/css/tagsinput.css`
- `app/assets/plugins/morris/css/morris.css`
- `app/assets/plugins/notifications/css/lobibox.css`
- `app/assets/plugins/notifications/css/lobibox.min.css`
- `app/assets/plugins/select2/css/select2-bootstrap4.css`
- `app/assets/plugins/select2/css/select2.min.css`
- `app/assets/stylesheets/fullcalendar/css/main.css`
- `app/assets/stylesheets/site/css/base.css`
- `app/assets/stylesheets/site/css/contato.css`
- `app/assets/stylesheets/site/css/footer.css`
- `app/assets/stylesheets/site/css/global.css`
- `app/assets/stylesheets/site/css/home.css`
- `app/assets/stylesheets/site/css/index.css`
- `app/assets/stylesheets/site/css/navigation.css`
- `app/assets/stylesheets/site/css/projetos.css`
- `app/assets/stylesheets/site/css/servicos.css`
- `app/assets/stylesheets/site/css/sobre.css`
- `app/assets/stylesheets/site/css/styles.css`

Checklist de validacao apos remover este lote:
- Login / logout
- Dashboard app e admin
- Cadastro register e telas de autenticacao
- Formularios de cliente, tecnico, OS e configuracoes
- Tabela de logs e filtros (flatpickr/select2)

## Lote 3 - Alto Risco
- Criterio: Arquivos de `app/javascript` sem prova forte de uso.
- Quantidade: 0


Checklist de validacao apos remover este lote:
- Login / logout
- Dashboard app e admin
- Cadastro register e telas de autenticacao
- Formularios de cliente, tecnico, OS e configuracoes
- Tabela de logs e filtros (flatpickr/select2)
