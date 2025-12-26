export function onlyDigits(value) {
  return (value || "").replace(/\D/g, "");
}

export function formatCPF(value) {
  const v = onlyDigits(value).slice(0, 11);
  if (v.length <= 3) return v;
  if (v.length <= 6) return `${v.slice(0,3)}.${v.slice(3)}`;
  if (v.length <= 9) return `${v.slice(0,3)}.${v.slice(3,6)}.${v.slice(6)}`;
  return `${v.slice(0,3)}.${v.slice(3,6)}.${v.slice(6,9)}-${v.slice(9)}`;
}

export function formatCNPJ(value) {
  const v = onlyDigits(value).slice(0, 14);
  if (v.length <= 2) return v;
  if (v.length <= 5) return `${v.slice(0,2)}.${v.slice(2)}`;
  if (v.length <= 8) return `${v.slice(0,2)}.${v.slice(2,5)}.${v.slice(5)}`;
  if (v.length <= 12) return `${v.slice(0,2)}.${v.slice(2,5)}.${v.slice(5,8)}/${v.slice(8)}`;
  return `${v.slice(0,2)}.${v.slice(2,5)}.${v.slice(5,8)}/${v.slice(8,12)}-${v.slice(12)}`;
}

export function formatDoc(value) {
  const digits = onlyDigits(value);
  return digits.length <= 11 ? formatCPF(digits) : formatCNPJ(digits);
}

export function formatPhone(value) {
  const v = onlyDigits(value).slice(0, 11);
  const ddd = v.slice(0, 2);
  if (v.length <= 2) return `(${v}`;
  if (v.length <= 6) return `(${ddd}) ${v.slice(2)}`;
  if (v.length <= 10) return `(${ddd}) ${v.slice(2, 6)}-${v.slice(6)}`;
  return `(${ddd}) ${v.slice(2, 7)}-${v.slice(7)}`;
}

export function formatCEP(value) {
  const d = onlyDigits(value).slice(0, 8);
  if (d.length <= 5) return d;
  return `${d.slice(0, 5)}-${d.slice(5)}`;
}