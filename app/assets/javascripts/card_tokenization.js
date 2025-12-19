(function initCardTokenization() {
  function onReady(fn) {
    if (document.readyState === 'loading') {
      document.addEventListener('DOMContentLoaded', fn, { once: true });
      document.addEventListener('turbo:load', fn, { once: true });
      document.addEventListener('turbolinks:load', fn, { once: true });
    } else { fn(); }
  }

  onReady(function () {
    if (typeof window.MercadoPago === 'undefined') return;

    const publicKey = document.querySelector('meta[name="mp-public-key"]')?.content;
    if (!publicKey) return;

    const mp = new MercadoPago(publicKey, { locale: 'pt-BR' });

    const form =
      document.getElementById('signup-form') ||
      document.querySelector('form[action$="/signups"]') ||
      document.querySelector('.bs-stepper-content form') ||
      document.querySelector('form');

    if (!form) return;
    if (!form.id) form.id = 'signup-form';

    const q = (name) => form.querySelector(`[name="${name}"]`);
    const setId = (el, id) => { if (el && !el.id) el.id = id; return el?.id; };

    const numberEl = q('signup[card][card_number]');
    const expEl = q('signup[card][card_expiration]'); // MM/YY
    const cvvEl = q('signup[card][card_cvv]');
    const nameEl = q('signup[card][cardholder_name]');
    const docEl = q('signup[card][cardholder_document]');
    const emailEl = q('signup[user][email]') || q('signup[company][email]');

    // Mitiga interferência de extensões (password managers, etc.)
    const markIgnore = (el, ac) => {
      if (!el) return;
      el.setAttribute('autocomplete', ac || 'off');
      el.setAttribute('autocapitalize', 'off');
      el.setAttribute('spellcheck', 'false');
      el.setAttribute('data-lpignore', 'true');   // LastPass
      el.setAttribute('data-1p-ignore', 'true');  // 1Password
    };
    markIgnore(numberEl, 'cc-number'); numberEl?.setAttribute('inputmode', 'numeric');
    markIgnore(cvvEl, 'cc-csc');        cvvEl?.setAttribute('inputmode', 'numeric');
    markIgnore(expEl, 'cc-exp');        expEl?.setAttribute('inputmode', 'numeric');
    markIgnore(nameEl, 'cc-name');
    markIgnore(docEl, 'off');

    const numberId = setId(numberEl, 'mp_card_number');
    const expId    = setId(expEl,    'mp_card_expiration');
    const cvvId    = setId(cvvEl,    'mp_card_cvv');
    const nameId   = setId(nameEl,   'mp_cardholder_name');
    const emailId  = setId(emailEl,  'mp_cardholder_email');
    const docId    = setId(docEl,    'mp_identification_number');

    // Selects exigidos pelo cardForm (devem ser <select>, mesmo ocultos)
    function ensureHiddenSelect(id) {
      let el = document.getElementById(id);
      if (!el) {
        el = document.createElement('select');
        el.id = id;
        el.style.display = 'none';
        form.appendChild(el);
      }
      return el;
    }
    const idTypeSelect = ensureHiddenSelect('mp_identification_type');
    const installmentsSelect = ensureHiddenSelect('mp_installments');
    const issuerSelect = ensureHiddenSelect('mp_issuer');

    // Sincroniza CPF/CNPJ com o select de tipo
    const syncIdType = () => {
      const digits = (docEl?.value || '').replace(/\D/g, '');
      const target = digits.length > 11 ? 'CNPJ' : 'CPF';
      const trySet = () => {
        const opt = Array.from(idTypeSelect.options).find(o => o.value === target);
        if (opt) {
          idTypeSelect.value = target;
          idTypeSelect.dispatchEvent(new Event('change', { bubbles: true }));
          return true;
        }
        return false;
      };
      if (!trySet()) setTimeout(trySet, 120);
    };
    docEl?.addEventListener('input', syncIdType);

    function ensureHidden(name) {
      let input = form.querySelector(`input[name="${name}"]`);
      if (!input) {
        input = document.createElement('input');
        input.type = 'hidden';
        input.name = name;
        form.appendChild(input);
      }
      return input;
    }

    function removeSensitiveNames() {
      [
        'signup[card][card_number]',
        'signup[card][card_expiration]',
        'signup[card][card_cvv]',
      ].forEach((name) => {
        const el = q(name);
        if (el) el.removeAttribute('name');
      });
    }

    function shouldTokenize() {
      const method = form.querySelector('input[name="signup[payment_method]"]:checked')?.value;
      const hasCardFields = !!q('signup[card][card_number]');
      if (method) return method === 'credit_card';
      return hasCardFields;
    }

    const cardForm = mp.cardForm({
      amount: '1',
      autoMount: true,
      form: {
        id: form.id,
        cardholderName: { id: nameId },
        cardholderEmail: { id: emailId },
        cardNumber: { id: numberId },
        securityCode: { id: cvvId },
        expirationDate: { id: expId },
        installments: { id: 'mp_installments' },
        identificationType: { id: 'mp_identification_type' },
        identificationNumber: { id: docId },
        issuer: { id: 'mp_issuer' },
      },
      callbacks: {
        onFormMounted: (error) => {
          if (error) {
            console.error('cardForm mount error', error);
            return;
          }
          syncIdType();
        },
        onSubmit: (event) => {
          if (!shouldTokenize()) return;
          event.preventDefault();

          const { token } = cardForm.getCardFormData();
          if (!token) {
            alert('Não foi possível tokenizar o cartão.');
            return;
          }
 
          ensureHidden('signup[card_token]').value = token;
          removeSensitiveNames();
          form.submit();
        },
        onError: (errors) => {
          console.error('cardForm error', errors);
          alert('Erro ao tokenizar o cartão. Verifique os dados e tente novamente.');
        }
      }
    });

    // Expor para testes no console (remover em produção)
    window.__mpCardForm = cardForm;
  });
})();