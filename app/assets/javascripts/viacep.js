document.addEventListener("DOMContentLoaded", function() {
  const cepInput = document.querySelector('input[name*="zip_code"]');
  if (!cepInput) return;

  cepInput.addEventListener("blur", function() {
    const cep = cepInput.value.replace(/\D/g, '');
    if (cep.length !== 8) return;

    fetch(`https://viacep.com.br/ws/${cep}/json/`)
      .then(response => response.json())
      .then(data => {
        if (data.erro) {
          alert("CEP não encontrado!");
          return;
        }
        document.querySelector('input[name*="street"]').value = data.logradouro || '';
        document.querySelector('input[name$="[city]"]').value = data.localidade || '';
        document.querySelector('input[name*="neighborhood"]').value = data.bairro || '';
        document.querySelector('input[name*="state"]').value = data.uf || '';
      });
  });
});