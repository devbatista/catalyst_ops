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
    const expEl = q('signup[card][card_expiration]');
    const cvvEl = q('signup[card][card_cvv]');
    const nameEl = q('signup[card][cardholder_name]');
    const docEl = q('signup[card][cardholder_document]');
    const emailEl = q('signup[user][email]') || q('signup[company][email]');

    // Mitiga interferência de extensões
    const markIgnore = (el, ac) => {
      if (!el) return;
      el.setAttribute('autocomplete', ac || 'off');
      el.setAttribute('autocapitalize', 'off');
      el.setAttribute('spellcheck', 'false');
      el.setAttribute('data-lpignore', 'true');
      el.setAttribute('data-1p-ignore', 'true');
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
    ensureHiddenSelect('mp_identification_type');
    ensureHiddenSelect('mp_installments');
    ensureHiddenSelect('mp_issuer');

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
      const ccForm = document.getElementById('credit-card-form');
      return method === 'credit_card' && ccForm && !ccForm.classList.contains('d-none');
    }

    let cardFormInstance = null;

    function mountCardForm() {
      if (cardFormInstance) return;
      cardFormInstance = mp.cardForm({
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
          },
          onSubmit: (event) => {
            if (!shouldTokenize()) return;
            event.preventDefault();

            const { token } = cardFormInstance.getCardFormData();
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
      window.__mpCardForm = cardFormInstance;
    }

    function unmountCardForm() {
      cardFormInstance = null;
      window.__mpCardForm = undefined;
      // O SDK não tem destroy, mas isso impede submit custom
    }

    // Listener para método de pagamento
    document.querySelectorAll('input[name="signup[payment_method]"]').forEach(radio => {
      radio.addEventListener('change', function() {
        if (this.value === 'credit_card') {
          mountCardForm();
        } else {
          unmountCardForm();
        }
      });
    });

    // Estado inicial ao carregar
    const selected = document.querySelector('input[name="signup[payment_method]"]:checked');
    if (selected && selected.value === 'credit_card') {
      mountCardForm();
    }
  });
})();