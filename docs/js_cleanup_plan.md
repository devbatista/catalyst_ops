# JS Cleanup Plan (3 Lotes)

Plano gerado a partir de `docs/js_usage_audit.json`.
Objetivo: remover JS não usado com risco controlado, validando a cada lote.

## Resumo
- Lote 1 (baixo risco): 69 arquivos
- Lote 2 (medio risco): 76 arquivos
- Lote 3 (alto risco): 5 arquivos

## Lote 1 - Baixo Risco
- Critério: Duplicatas em `app/assets/stylesheets/**` com arquivo equivalente em outro caminho.
- Quantidade: 69

- `app/assets/stylesheets/js/index2.js`
- `app/assets/stylesheets/js/index3.js`
- `app/assets/stylesheets/js/widgets.js`
- `app/assets/stylesheets/plugins/Drag-And-Drop/dist/imageuploadify.min.js`
- `app/assets/stylesheets/plugins/apexcharts-bundle/js/apex-custom.js`
- `app/assets/stylesheets/plugins/apexcharts-bundle/js/apexcharts.js`
- `app/assets/stylesheets/plugins/apexcharts-bundle/js/apexcharts.min.js`
- `app/assets/stylesheets/plugins/bootstrap-material-datetimepicker/js/bootstrap-material-datetimepicker.min.js`
- `app/assets/stylesheets/plugins/bootstrap-material-datetimepicker/js/moment.min.js`
- `app/assets/stylesheets/plugins/bs-stepper/css/custom.js`
- `app/assets/stylesheets/plugins/bs-stepper/js/index.js`
- `app/assets/stylesheets/plugins/chartjs/js/Chart.extension.js`
- `app/assets/stylesheets/plugins/chartjs/js/chartjs-custom.js`
- `app/assets/stylesheets/plugins/datatable/js/dataTables.bootstrap5.min.js`
- `app/assets/stylesheets/plugins/datatable/js/jquery.dataTables.min.js`
- `app/assets/stylesheets/plugins/datetimepicker/js/legacy.js`
- `app/assets/stylesheets/plugins/datetimepicker/js/picker.date.js`
- `app/assets/stylesheets/plugins/datetimepicker/js/picker.js`
- `app/assets/stylesheets/plugins/datetimepicker/js/picker.time.js`
- `app/assets/stylesheets/plugins/fancy-file-uploader/cors/jquery.postmessage-transport.js`
- `app/assets/stylesheets/plugins/fancy-file-uploader/cors/jquery.xdr-transport.js`
- `app/assets/stylesheets/plugins/fancy-file-uploader/jquery.fancy-fileupload.js`
- `app/assets/stylesheets/plugins/fancy-file-uploader/jquery.fileupload.js`
- `app/assets/stylesheets/plugins/fancy-file-uploader/jquery.iframe-transport.js`
- `app/assets/stylesheets/plugins/fancy-file-uploader/jquery.ui.widget.js`
- `app/assets/stylesheets/plugins/form-repeater/repeater.js`
- `app/assets/stylesheets/plugins/fullcalendar/js/main.js`
- `app/assets/stylesheets/plugins/fullcalendar/js/main.min.js`
- `app/assets/stylesheets/plugins/gmaps/map-custom-script.js`
- `app/assets/stylesheets/plugins/highcharts/js/accessibility.js`
- `app/assets/stylesheets/plugins/highcharts/js/cylinder.js`
- `app/assets/stylesheets/plugins/highcharts/js/export-data.js`
- `app/assets/stylesheets/plugins/highcharts/js/exporting.js`
- `app/assets/stylesheets/plugins/highcharts/js/funnel3d.js`
- `app/assets/stylesheets/plugins/highcharts/js/highcharts-3d.js`
- `app/assets/stylesheets/plugins/highcharts/js/highcharts-custom.script.js`
- `app/assets/stylesheets/plugins/highcharts/js/highcharts-more.js`
- `app/assets/stylesheets/plugins/highcharts/js/highcharts.js`
- `app/assets/stylesheets/plugins/highcharts/js/solid-gauge.js`
- `app/assets/stylesheets/plugins/highcharts/js/variable-pie.js`
- `app/assets/stylesheets/plugins/input-tags/js/tagsinput.js`
- `app/assets/stylesheets/plugins/jquery-knob/excanvas.js`
- `app/assets/stylesheets/plugins/jquery-knob/jquery.knob.js`
- `app/assets/stylesheets/plugins/jquery.easy-pie-chart/easy-pie-chart.init.js`
- `app/assets/stylesheets/plugins/jquery.easy-pie-chart/easypiechart.min.js`
- `app/assets/stylesheets/plugins/jquery.easy-pie-chart/jquery.easypiechart.min.js`
- `app/assets/stylesheets/plugins/morris/js/morris-data.js`
- `app/assets/stylesheets/plugins/morris/js/morris.js`
- `app/assets/stylesheets/plugins/morris/js/morris.min.js`
- `app/assets/stylesheets/plugins/notifications/js/lobibox.js`
- `app/assets/stylesheets/plugins/notifications/js/lobibox.min.js`
- `app/assets/stylesheets/plugins/notifications/js/messageboxes.js`
- `app/assets/stylesheets/plugins/notifications/js/messageboxes.min.js`
- `app/assets/stylesheets/plugins/notifications/js/notification-custom-script.js`
- `app/assets/stylesheets/plugins/notifications/js/notifications.js`
- `app/assets/stylesheets/plugins/notifications/js/notifications.min.js`
- `app/assets/stylesheets/plugins/raphael/raphael-min.js`
- `app/assets/stylesheets/plugins/select2/js/select2-custom.js`
- `app/assets/stylesheets/plugins/select2/js/select2.min.js`
- `app/assets/stylesheets/plugins/sparkline-charts/apex-sparkline-charts.js`
- `app/assets/stylesheets/plugins/sparkline-charts/jquery.sparkline.min.js`
- `app/assets/stylesheets/plugins/sparkline-charts/sparkline-chart-script.js`
- `app/assets/stylesheets/plugins/validation/jquery.validate.min.js`
- `app/assets/stylesheets/plugins/validation/validation-script.js`
- `app/assets/stylesheets/plugins/vectormap/jquery-jvectormap-au-mill.js`
- `app/assets/stylesheets/plugins/vectormap/jquery-jvectormap-in-mill.js`
- `app/assets/stylesheets/plugins/vectormap/jquery-jvectormap-uk-mill-en.js`
- `app/assets/stylesheets/plugins/vectormap/jquery-jvectormap-us-aea-en.js`
- `app/assets/stylesheets/plugins/vectormap/jvectormap.custom.js`

Checklist de validacao apos remover este lote:
- Login / logout
- Dashboard app e admin
- Cadastro register (com e sem cupom)
- Criacao/edicao de cliente, tecnico e OS
- Fluxos de pagamento (pix/boleto) e tela de logs

## Lote 2 - Medio Risco
- Critério: Arquivos marcados como `unused_candidate` fora de `app/javascript` (normalmente libs/plugins soltos).
- Quantidade: 76

- `app/assets/js/index2.js`
- `app/assets/js/index3.js`
- `app/assets/js/widgets.js`
- `app/assets/plugins/Drag-And-Drop/dist/imageuploadify.min.js`
- `app/assets/plugins/apexcharts-bundle/js/apex-custom.js`
- `app/assets/plugins/apexcharts-bundle/js/apexcharts.js`
- `app/assets/plugins/apexcharts-bundle/js/apexcharts.min.js`
- `app/assets/plugins/bootstrap-material-datetimepicker/js/bootstrap-material-datetimepicker.min.js`
- `app/assets/plugins/bootstrap-material-datetimepicker/js/moment.min.js`
- `app/assets/plugins/bs-stepper/css/custom.js`
- `app/assets/plugins/bs-stepper/js/index.js`
- `app/assets/plugins/chartjs/js/Chart.extension.js`
- `app/assets/plugins/chartjs/js/chartjs-custom.js`
- `app/assets/plugins/datatable/js/dataTables.bootstrap5.min.js`
- `app/assets/plugins/datatable/js/jquery.dataTables.min.js`
- `app/assets/plugins/datetimepicker/js/legacy.js`
- `app/assets/plugins/datetimepicker/js/picker.date.js`
- `app/assets/plugins/datetimepicker/js/picker.js`
- `app/assets/plugins/datetimepicker/js/picker.time.js`
- `app/assets/plugins/fancy-file-uploader/cors/jquery.postmessage-transport.js`
- `app/assets/plugins/fancy-file-uploader/cors/jquery.xdr-transport.js`
- `app/assets/plugins/fancy-file-uploader/jquery.fancy-fileupload.js`
- `app/assets/plugins/fancy-file-uploader/jquery.fileupload.js`
- `app/assets/plugins/fancy-file-uploader/jquery.iframe-transport.js`
- `app/assets/plugins/fancy-file-uploader/jquery.ui.widget.js`
- `app/assets/plugins/form-repeater/repeater.js`
- `app/assets/plugins/fullcalendar/js/main.js`
- `app/assets/plugins/fullcalendar/js/main.min.js`
- `app/assets/plugins/gmaps/map-custom-script.js`
- `app/assets/plugins/highcharts/js/accessibility.js`
- `app/assets/plugins/highcharts/js/cylinder.js`
- `app/assets/plugins/highcharts/js/export-data.js`
- `app/assets/plugins/highcharts/js/exporting.js`
- `app/assets/plugins/highcharts/js/funnel3d.js`
- `app/assets/plugins/highcharts/js/highcharts-3d.js`
- `app/assets/plugins/highcharts/js/highcharts-custom.script.js`
- `app/assets/plugins/highcharts/js/highcharts-more.js`
- `app/assets/plugins/highcharts/js/highcharts.js`
- `app/assets/plugins/highcharts/js/solid-gauge.js`
- `app/assets/plugins/highcharts/js/variable-pie.js`
- `app/assets/plugins/input-tags/js/tagsinput.js`
- `app/assets/plugins/jquery-knob/excanvas.js`
- `app/assets/plugins/jquery-knob/jquery.knob.js`
- `app/assets/plugins/jquery.easy-pie-chart/easy-pie-chart.init.js`
- `app/assets/plugins/jquery.easy-pie-chart/easypiechart.min.js`
- `app/assets/plugins/jquery.easy-pie-chart/jquery.easypiechart.min.js`
- `app/assets/plugins/morris/js/morris-data.js`
- `app/assets/plugins/morris/js/morris.js`
- `app/assets/plugins/morris/js/morris.min.js`
- `app/assets/plugins/notifications/js/lobibox.js`
- `app/assets/plugins/notifications/js/lobibox.min.js`
- `app/assets/plugins/notifications/js/messageboxes.js`
- `app/assets/plugins/notifications/js/messageboxes.min.js`
- `app/assets/plugins/notifications/js/notification-custom-script.js`
- `app/assets/plugins/notifications/js/notifications.js`
- `app/assets/plugins/notifications/js/notifications.min.js`
- `app/assets/plugins/raphael/raphael-min.js`
- `app/assets/plugins/select2/js/select2-custom.js`
- `app/assets/plugins/select2/js/select2.min.js`
- `app/assets/plugins/sparkline-charts/apex-sparkline-charts.js`
- `app/assets/plugins/sparkline-charts/jquery.sparkline.min.js`
- `app/assets/plugins/sparkline-charts/sparkline-chart-script.js`
- `app/assets/plugins/validation/jquery.validate.min.js`
- `app/assets/plugins/validation/validation-script.js`
- `app/assets/plugins/vectormap/jquery-jvectormap-au-mill.js`
- `app/assets/plugins/vectormap/jquery-jvectormap-in-mill.js`
- `app/assets/plugins/vectormap/jquery-jvectormap-uk-mill-en.js`
- `app/assets/plugins/vectormap/jquery-jvectormap-us-aea-en.js`
- `app/assets/plugins/vectormap/jvectormap.custom.js`
- `app/assets/stylesheets/fullcalendar/js/main.js`
- `app/assets/stylesheets/plugins/bs-stepper/js/index.spec.js`
- `app/assets/stylesheets/plugins/bs-stepper/js/listeners.js`
- `app/assets/stylesheets/plugins/bs-stepper/js/main.js`
- `app/assets/stylesheets/plugins/bs-stepper/js/polyfill.js`
- `app/assets/stylesheets/plugins/bs-stepper/js/util.js`
- `app/assets/stylesheets/site/js/main.js`

Checklist de validacao apos remover este lote:
- Login / logout
- Dashboard app e admin
- Cadastro register (com e sem cupom)
- Criacao/edicao de cliente, tecnico e OS
- Fluxos de pagamento (pix/boleto) e tela de logs

## Lote 3 - Alto Risco
- Critério: Arquivos de `app/javascript` sem prova forte de uso (podem ser acionados por fluxo não coberto).
- Quantidade: 5

- `app/javascript/application.js`
- `app/javascript/controllers/application.js`
- `app/javascript/controllers/hello_controller.js`
- `app/javascript/controllers/index.js`
- `app/javascript/controllers/stimulus.js`

Checklist de validacao apos remover este lote:
- Login / logout
- Dashboard app e admin
- Cadastro register (com e sem cupom)
- Criacao/edicao de cliente, tecnico e OS
- Fluxos de pagamento (pix/boleto) e tela de logs
