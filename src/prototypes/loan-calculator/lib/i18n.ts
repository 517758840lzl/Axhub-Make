import type { AppLocale } from './types';

/** Product display name. Change it here when renaming. */
export const appTitle = 'LoanCalcWise';

export type { AppLocale };

export const APP_LOCALES: {
  id: AppLocale;
  nativeLabel: string;
}[] = [
  { id: 'en', nativeLabel: 'English' },
  { id: 'es', nativeLabel: 'Español' },
];

const en = {
  'tab.calc': 'Calc',
  'tab.savings': 'Save',
  'tab.profile': 'Me',
  'nav.main': 'Main navigation',
  'nav.back': 'Back',

  'cat.mortgage': 'Home',
  'cat.auto': 'Auto',
  'cat.personal': 'Personal',
  'cat.dual': 'Dual',
  'cat.other': 'Other',
  'dual.partA': 'Loan A',
  'dual.partB': 'Loan B',
  'dual.combinedMonthly': 'Combined monthly',
  'dual.combinedFirst': 'Combined first month',
  'dual.partBreakdown': 'Per-loan breakdown',
  'dual.insight':
    'Combined monthly about {monthly}; total interest about {interest}; total cost about {total}.',
  'dual.params': 'Loan details',

  'mode.equalPayment': 'Equal payment',
  'mode.equalPrincipal': 'Equal principal',

  'home.title': appTitle,
  'home.subtitle': 'Auto · Home · Personal · Dual · Compare',
  'home.badge.local': 'Stored on device',
  'home.badge.saved': '{count} saved',
  'home.loanType': 'Loan type',
  'home.repayMode': 'Repayment',
  'home.params': 'Loan details',
  'home.paramsAuto': 'Loan details',
  'home.preview': 'Live preview · {mode}',
  'home.previewDown': ' · Down {pct}%',
  'home.totalInterest': 'Total interest',
  'home.totalPayment': 'Total cost',
  'home.principal': 'Principal',
  'home.vehiclePrice': 'Vehicle price',
  'home.downPct': 'Down payment %',
  'home.downAmount': 'Down payment',
  'home.loanAmount': 'Loan amount',
  'home.rate': 'Annual rate',
  'home.term': 'Term',
  'home.year': 'yr',
  'home.month': 'mo',
  'home.yearsN': '{n} yr',
  'home.monthsN': '{n} mo',
  'home.termByMonth': 'By month',
  'home.termByYear': 'By year',
  'home.termCustom': 'Custom',
  'home.wan': '{n}0k',
  'home.wanWithUnit': '{symbol}{n}0k',
  'home.million': '{n}M',
  'home.feature.ratio': 'Split',
  'home.feature.amort': 'Schedule',
  'home.feature.compare': 'Compare',
  'home.cta': 'Calculate',
  'home.disclaimer': 'Estimates only',
  'home.unit.yuan': '',
  'home.fillFirst': 'Please complete the loan fields first',
  'home.ratePositive': 'Interest rate must be greater than 0',
  'home.downOverPrice': 'Down payment cannot exceed the vehicle price',
  'home.loanOverPrice': 'Loan amount cannot exceed the vehicle price',

  'result.title': 'Results',
  'result.monthly': 'Monthly',
  'result.firstLast': 'First → last payment',
  'result.principal': 'Principal',
  'result.interest': 'Interest',
  'result.interestShare': 'Interest share',
  'result.totalPayment': 'Total cost',
  'result.totalInterest': 'Total interest',
  'result.loanPrincipal': 'Principal',
  'result.vehicle': 'Vehicle price',
  'result.downPayment': 'Down payment',
  'result.insights': 'Summary',
  'result.amort': 'Amortization schedule',
  'result.compare': 'Add to compare',
  'result.save': 'Save plan',
  'result.savings': 'Set a savings buffer',
  'result.insight.1':
    'With {mode}, paid off in about {years} years; interest is about {share}% of total cost.',
  'result.insight.2':
    'At about {monthly}/mo, total interest is about {interest}.',
  'result.insight.3': 'Principal {principal}, annual rate {rate}%.',
  'result.insight.auto':
    'Price {vehicle}, down {pct}% ({down}), loan {principal}.',

  'amort.title': 'Amortization',
  'amort.periods': '{n} periods',
  'amort.byMonth': 'Monthly',
  'amort.byYear': 'Yearly',
  'amort.byCustom': 'Custom',
  'amort.fromPeriod': 'From',
  'amort.toPeriod': 'To',
  'amort.rangeHint': 'Filter by period, 1–{max}',
  'amort.rangeOrder': 'End period cannot be earlier than the start',
  'amort.rangeBounds': 'Use a period from 1 to {max}',
  'amort.showing': 'Showing {n} periods',
  'amort.pageYear': 'Year {n} · {from}–{to}',
  'amort.pageYears': 'Years {from}–{to}',
  'amort.pagePeriods': '{from}–{to}',
  'amort.prevPage': 'Previous',
  'amort.nextPage': 'Next',
  'amort.rangeSum': 'Range total',
  'amort.col.period': '#',
  'amort.col.year': 'Yr',
  'amort.col.payment': 'Payment',
  'amort.col.principal': 'Principal',
  'amort.col.interest': 'Interest',
  'amort.col.balance': 'Balance',

  'compare.title': 'Compare',
  'compare.needTwo':
    'Select at least 2 plans to compare. Add from Saved, or calculate again and tap Add to compare.',
  'compare.goSaved': 'Open saved plans',
  'compare.metric': 'Metric',
  'compare.remove': 'Remove',
  'compare.principal': 'Principal',
  'compare.rate': 'Rate',
  'compare.term': 'Term',
  'compare.termMonths': '{n} mo',
  'compare.monthly': 'Monthly',
  'compare.mode': 'Repayment',
  'compare.firstMonth': 'First payment',
  'compare.lastMonth': 'Last payment',
  'compare.interestShare': 'Interest share',
  'compare.dailyInterest': 'Interest / day',
  'compare.category': 'Loan type',
  'compare.downPayment': 'Down payment',
  'compare.summaryTitle': 'Summary',
  'compare.summaryTwo': '{low} pays less interest: {lowInterestAmt}, {interestDiff} less than {high}. Lowest monthly payment is {monthly} at {monthlyAmt}.',
  'compare.summaryTwoSame': '{low} has both lower interest and a lower monthly payment: interest {lowInterestAmt}, {interestDiff} less than {high}; monthly {monthlyAmt}.',
  'compare.summaryMany': 'Among {n} plans, {low} has the least interest at {lowInterestAmt}, {interestDiff} less than {high}. Lowest monthly payment is {monthly} at {monthlyAmt}.',
  'compare.summaryManySame': 'Among {n} plans, {low} has the least interest and the lowest monthly payment: interest {lowInterestAmt}, {interestDiff} less than {high}; monthly {monthlyAmt}.',
  'compare.chartBar': 'Key amounts',
  'compare.addSaved': 'Add a saved plan',
  'compare.addOne': 'Add',
  'compare.perMonth': '{amount}/mo',
  'compare.hint': 'From Results, tap Add to compare to include the latest run.',
  'compare.max': 'Compare up to 3 plans',
  'compare.added': 'Added to compare',
  'compare.addedNeedOne': 'Added. Choose one more to compare.',

  'savings.title': 'Savings goals',
  'savings.subtitle': 'Buffer for monthly payments',
  'savings.inProgress': '{n} active',
  'savings.completed': '{n} completed',
  'savings.empty': 'No goals yet. Create one from Results, or add manually.',
  'savings.new': 'New goal',
  'savings.savedTotal': 'Saved',
  'savings.targetTotal': 'Target',
  'savings.linkedHint': '{n} loan plans linked — create goals from Results',
  'savings.insights': 'Insights',
  'savings.insightsFor': '{name} · tips',
  'savings.create': 'New',
  'savings.name': 'Name',
  'savings.namePh': 'Enter a name',
  'savings.target': 'Target amount',
  'savings.amountPh': 'Enter a target amount',
  'savings.createCta': 'Create',
  'savings.defaultName': 'Payment buffer',
  'savings.depositWithdraw': 'Deposit / withdraw',
  'savings.amount': 'Amount',
  'savings.deposit': 'Deposit',
  'savings.withdraw': 'Withdraw',
  'savings.flow': 'Activity',
  'savings.noTx': 'No activity yet',
  'savings.insufficient': 'Insufficient balance',
  'savings.done': 'Saved',
  'savings.todo': 'Left',
  'savings.withdrawn': 'Withdrawn',
  'savings.progress': 'Progress',
  'savings.created': 'Goal created',
  'savings.deleteTitle': 'Delete savings goal',
  'savings.deleteConfirm': 'Delete this savings goal?',
  'savings.missing': 'Goal not found',
  'savings.eta.done': 'Completed',
  'savings.eta.start': '{amount} left — deposit to estimate finish',
  'savings.eta.continue': '{amount} left — keep depositing to refresh',
  'savings.eta.long': '{amount} left — pace is slow',
  'savings.eta.soon': '{amount} left — about 1 month',
  'savings.eta.months': '{amount} left — about {months} months',
  'savings.buffer.intro': 'Aim for 3–6 months of payments',
  'savings.buffer.noLink': 'Link a loan plan to see payment buffer',
  'savings.buffer.high': 'About {months} months covered — above guide',
  'savings.buffer.ok': 'About {months} months covered — on track',
  'savings.buffer.low': 'About {months} months covered — {gap} to 3 months',

  'profile.title': 'Profile',
  'profile.subtitle': 'Local profile & saved plans',
  'profile.localOnly': 'Data stays on this device',
  'profile.editTitle': 'Edit profile',
  'profile.gender': 'Gender',
  'profile.gender.male': 'Male',
  'profile.gender.female': 'Female',
  'profile.gender.private': 'Private',
  'profile.savedCount': 'Saved plans',
  'profile.savingsCount': 'Savings goals',
  'profile.saved': 'Saved plans',
  'profile.settings': 'Preferences',
  'profile.data': 'Data',
  'profile.aboutUs': 'About us',
  'profile.about': 'Privacy policy',

  'saved.title': 'Saved plans',
  'saved.empty': 'No saved plans yet. Run a calculation and save it.',
  'saved.goCalc': 'Go calculate',
  'saved.fav': 'Favorite',
  'saved.unfav': 'Unfavorite',
  'saved.compare': 'Compare',
  'saved.leaveCompare': 'Leave compare',
  'saved.delete': 'Delete',
  'saved.deleteTitle': 'Delete plan',
  'saved.deleteConfirm': 'Delete this saved plan?',
  'saved.inCompare': 'In compare',
  'saved.meta': 'Principal {principal} · {rate}% · {months} mo',
  'saved.deleted': 'Deleted',

  'settings.title': 'Preferences',
  'settings.nickname': 'Nickname',
  'settings.avatar': 'Avatar',
  'settings.decimals': 'Decimals',
  'settings.language': 'Language',
  'settings.save': 'Save',
  'settings.defaultNick': 'Borrower',

  'currency.label': 'Display currency',
  'currency.current': 'Now {symbol} {name}',
  'currency.pick': 'Choose currency',
  'currency.CNY': 'Chinese Yuan',
  'currency.USD': 'US Dollar',
  'currency.EUR': 'Euro',
  'currency.GBP': 'British Pound',
  'currency.INR': 'Indian Rupee',
  'currency.JPY': 'Japanese Yen',
  'currency.HKD': 'Hong Kong Dollar',
  'currency.SGD': 'Singapore Dollar',
  'currency.AUD': 'Australian Dollar',
  'currency.CAD': 'Canadian Dollar',
  'currency.KRW': 'Korean Won',
  'currency.THB': 'Thai Baht',

  'data.title': 'Data',
  'data.clear': 'Clear plans & savings',
  'data.hint':
    'Clears loan plans and savings only. Nickname, currency, and language stay.',
  'data.confirm':
    'Clear all calculation and savings data? Preferences will be kept.',
  'data.cleared': 'Business data cleared',

  'aboutUs.title': 'About us',
  'aboutUs.body':
    'Dedicated to people preparing to borrow, this calculator builds repayment estimates you can check and plan comparisons you can set side by side. Enter an amount, annual rate, and term to see the monthly payment, total interest, and total amount due before you apply.\n\nIt covers home, auto, personal, and combined loans. A combined loan lists both parts side by side, with principal, rate, and monthly payment, plus the combined total. An auto loan can derive the amount from the vehicle price and down payment. Repayment methods are equal installments and equal principal: the former keeps each payment the same; the latter starts higher and usually costs less interest overall.\n\nThe amortization schedule lists principal, interest, and remaining principal for each period. Compare holds up to 3 plans; 2 are enough to contrast total interest and the monthly payment. A savings goal can be prefilled at about 3 times the monthly payment, then record later deposits and withdrawals.\n\nThe interface is available in English and Spanish. Amounts can be shown with common currency symbols. Switching currency changes the symbol and decimal places only; saved amounts are not converted at an exchange rate. Plans can be saved under Profile and opened again, and can be marked as favorites.',
  'about.title': 'Privacy policy',

  'toast.savedProfile': 'Saved to Profile',
  'toast.alreadySaved': 'This plan is already saved',
  'common.back': 'Back',
  'common.missing': 'Not found',
  'splash.subtitle': 'Instant estimates · On-device privacy · Savings',
  'savings.fab': 'New savings goal',
  'savings.detailTitle': 'Savings detail',
  'savings.newTitle': 'New savings',
  'tag.label': 'Tags',
  'tag.custom': 'Custom tag, press Enter to add',
  'tag.add': 'Add',
  'tag.needOne': 'Pick at least one tag to filter',
  'tag.remove': 'Remove {name}',
  'tag.all': 'All',
  'tag.calcBadge': 'Calc',
  'tag.mortgage': 'Mortgage',
  'tag.auto': 'Auto',
  'tag.consumer': 'Personal',
  'tag.payment': 'Payment',
  'tag.insurance': 'Insurance',
  'tag.reno': 'Renovation',
  'tag.edu': 'Education',
  'tag.medical': 'Medical',
  'tag.daily': 'Daily',
  'tag.other': 'Other',
  'seed.mortgageNote': 'Sample mortgage plan',
  'seed.autoNote': 'Sample auto plan',
  'seed.savingsName': 'Sample payment buffer',
} as const;

export type MessageKey = keyof typeof en;

const es: Record<MessageKey, string> = {
  'tab.calc': 'Calcular',
  'tab.savings': 'Ahorro',
  'tab.profile': 'Yo',
  'nav.main': 'Navegación principal',
  'nav.back': 'Atrás',

  'cat.mortgage': 'Hipoteca',
  'cat.auto': 'Auto',
  'cat.personal': 'Personal',
  'cat.dual': 'Doble',
  'cat.other': 'Otro',
  'dual.partA': 'Préstamo A',
  'dual.partB': 'Préstamo B',
  'dual.combinedMonthly': 'Cuota combinada',
  'dual.combinedFirst': 'Primera cuota combinada',
  'dual.partBreakdown': 'Detalle por préstamo',
  'dual.insight':
    'Cuota combinada ~{monthly}; interés total ~{interest}; costo total ~{total}.',
  'dual.params': 'Datos del préstamo',

  'mode.equalPayment': 'Cuota fija',
  'mode.equalPrincipal': 'Capital fijo',

  'home.title': appTitle,
  'home.subtitle': 'Auto · Hipoteca · Personal · Doble · Comparar',
  'home.badge.local': 'Datos en el dispositivo',
  'home.badge.saved': '{count} guardados',
  'home.loanType': 'Tipo de préstamo',
  'home.repayMode': 'Amortización',
  'home.params': 'Datos del préstamo',
  'home.paramsAuto': 'Datos del préstamo',
  'home.preview': 'Vista previa · {mode}',
  'home.previewDown': ' · Entrada {pct}%',
  'home.totalInterest': 'Interés total',
  'home.totalPayment': 'Costo total',
  'home.principal': 'Capital',
  'home.vehiclePrice': 'Precio del vehículo',
  'home.downPct': '% de entrada',
  'home.downAmount': 'Entrada',
  'home.loanAmount': 'Importe del préstamo',
  'home.rate': 'Tasa anual',
  'home.term': 'Plazo',
  'home.year': 'a',
  'home.month': 'm',
  'home.yearsN': '{n} a',
  'home.monthsN': '{n} meses',
  'home.termByMonth': 'Por meses',
  'home.termByYear': 'Por años',
  'home.termCustom': 'Otro',
  'home.wan': '{n}0 mil',
  'home.wanWithUnit': '{symbol}{n}0 mil',
  'home.million': '{n}M',
  'home.feature.ratio': 'Reparto',
  'home.feature.amort': 'Tabla',
  'home.feature.compare': 'Comparar',
  'home.cta': 'Calcular',
  'home.disclaimer': 'Solo estimación',
  'home.unit.yuan': '',
  'home.fillFirst': 'Completa los campos del préstamo',
  'home.ratePositive': 'La tasa debe ser mayor que 0',
  'home.downOverPrice': 'La entrada no puede superar el precio del vehículo',
  'home.loanOverPrice': 'El importe del préstamo no puede superar el precio del vehículo',

  'result.title': 'Resultados',
  'result.monthly': 'Cuota',
  'result.firstLast': 'Primera → última cuota',
  'result.principal': 'Capital',
  'result.interest': 'Interés',
  'result.interestShare': '% de interés',
  'result.totalPayment': 'Costo total',
  'result.totalInterest': 'Interés total',
  'result.loanPrincipal': 'Capital',
  'result.vehicle': 'Precio del vehículo',
  'result.downPayment': 'Entrada',
  'result.insights': 'Resumen',
  'result.amort': 'Ver tabla de amortización',
  'result.compare': 'Añadir a comparar',
  'result.save': 'Guardar plan',
  'result.savings': 'Crear meta de ahorro',
  'result.insight.1':
    'Con {mode}, se paga en unos {years} años; el interés es ~{share}% del total.',
  'result.insight.2':
    'Con ~{monthly}/mes, el interés total es ~{interest}.',
  'result.insight.3': 'Capital {principal}, tasa anual {rate}%.',
  'result.insight.auto':
    'Precio {vehicle}, entrada {pct}% ({down}), préstamo {principal}.',

  'amort.title': 'Amortización',
  'amort.periods': '{n} periodos',
  'amort.byMonth': 'Mensual',
  'amort.byYear': 'Anual',
  'amort.byCustom': 'Personalizado',
  'amort.fromPeriod': 'Desde',
  'amort.toPeriod': 'Hasta',
  'amort.rangeHint': 'Filtrar por periodo, 1–{max}',
  'amort.rangeOrder': 'El periodo final no puede ser menor que el inicial',
  'amort.rangeBounds': 'El periodo debe estar entre 1 y {max}',
  'amort.showing': 'Mostrando {n} periodos',
  'amort.pageYear': 'Año {n} · {from}–{to}',
  'amort.pageYears': 'Años {from}–{to}',
  'amort.pagePeriods': '{from}–{to}',
  'amort.prevPage': 'Anterior',
  'amort.nextPage': 'Siguiente',
  'amort.rangeSum': 'Total del rango',
  'amort.col.period': '#',
  'amort.col.year': 'Año',
  'amort.col.payment': 'Cuota',
  'amort.col.principal': 'Capital',
  'amort.col.interest': 'Interés',
  'amort.col.balance': 'Saldo',

  'compare.title': 'Comparar',
  'compare.needTwo':
    'Elige al menos 2 planes. Añade desde Guardados o calcula de nuevo y pulsa Añadir a comparar.',
  'compare.goSaved': 'Ir a planes guardados',
  'compare.metric': 'Métrica',
  'compare.remove': 'Quitar',
  'compare.principal': 'Capital',
  'compare.rate': 'Tasa',
  'compare.term': 'Plazo',
  'compare.termMonths': '{n} m',
  'compare.monthly': 'Cuota',
  'compare.mode': 'Método',
  'compare.firstMonth': 'Primera cuota',
  'compare.lastMonth': 'Última cuota',
  'compare.interestShare': '% interés',
  'compare.dailyInterest': 'Interés / día',
  'compare.category': 'Tipo',
  'compare.downPayment': 'Entrada',
  'compare.summaryTitle': 'Resumen',
  'compare.summaryTwo': '{low} paga menos interés: {lowInterestAmt}, {interestDiff} menos que {high}. La cuota más baja es {monthly}, {monthlyAmt}.',
  'compare.summaryTwoSame': '{low} tiene menos interés y menor cuota: interés {lowInterestAmt}, {interestDiff} menos que {high}; cuota {monthlyAmt}.',
  'compare.summaryMany': 'Entre {n} planes, {low} tiene el menor interés, {lowInterestAmt}, {interestDiff} menos que {high}. La cuota más baja es {monthly}, {monthlyAmt}.',
  'compare.summaryManySame': 'Entre {n} planes, {low} tiene el menor interés y la cuota más baja: interés {lowInterestAmt}, {interestDiff} menos que {high}; cuota {monthlyAmt}.',
  'compare.chartBar': 'Importes clave',
  'compare.addSaved': 'Añadir plan guardado',
  'compare.addOne': 'Añadir',
  'compare.perMonth': '{amount}/mes',
  'compare.hint': 'En Resultados, pulsa Añadir a comparar para incluir el último cálculo.',
  'compare.max': 'Máximo 3 planes',
  'compare.added': 'Añadido a comparar',
  'compare.addedNeedOne': 'Añadido. Elige uno más para comparar.',

  'savings.title': 'Metas de ahorro',
  'savings.subtitle': 'Colchón para la cuota',
  'savings.inProgress': '{n} activas',
  'savings.completed': '{n} completadas',
  'savings.empty': 'Aún no hay metas. Créalas desde Resultados o manualmente.',
  'savings.new': 'Nueva meta',
  'savings.savedTotal': 'Ahorrado',
  'savings.targetTotal': 'Objetivo',
  'savings.linkedHint': '{n} planes vinculados — crea metas desde Resultados',
  'savings.insights': 'Ideas',
  'savings.insightsFor': '{name} · ideas',
  'savings.create': 'Nueva',
  'savings.name': 'Nombre',
  'savings.namePh': 'Introduce un nombre',
  'savings.target': 'Importe objetivo',
  'savings.amountPh': 'Introduce el importe objetivo',
  'savings.createCta': 'Crear',
  'savings.defaultName': 'Colchón de cuota',
  'savings.depositWithdraw': 'Ingresar / retirar',
  'savings.amount': 'Importe',
  'savings.deposit': 'Ingresar',
  'savings.withdraw': 'Retirar',
  'savings.flow': 'Movimientos',
  'savings.noTx': 'Sin movimientos',
  'savings.insufficient': 'Saldo insuficiente',
  'savings.done': 'Ahorrado',
  'savings.todo': 'Falta',
  'savings.withdrawn': 'Retirado',
  'savings.progress': 'Progreso',
  'savings.created': 'Meta creada',
  'savings.deleteTitle': 'Eliminar meta de ahorro',
  'savings.deleteConfirm': '¿Eliminar esta meta de ahorro?',
  'savings.missing': 'Meta no encontrada',
  'savings.eta.done': 'Completada',
  'savings.eta.start': 'Faltan {amount}; ingresa para estimar',
  'savings.eta.continue': 'Faltan {amount}; sigue ingresando',
  'savings.eta.long': 'Faltan {amount}; ritmo lento',
  'savings.eta.soon': 'Faltan {amount}; ~1 mes',
  'savings.eta.months': 'Faltan {amount}; ~{months} meses',
  'savings.buffer.intro': 'Apunta a 3–6 meses de cuota',
  'savings.buffer.noLink': 'Vincula un plan para ver el colchón',
  'savings.buffer.high': 'Cubres ~{months} meses — por encima',
  'savings.buffer.ok': 'Cubres ~{months} meses — en rango',
  'savings.buffer.low': 'Cubres ~{months} meses — faltan {gap} para 3',

  'profile.title': 'Perfil',
  'profile.subtitle': 'Perfil local y planes guardados',
  'profile.localOnly': 'Los datos quedan en este dispositivo',
  'profile.editTitle': 'Editar perfil',
  'profile.gender': 'Género',
  'profile.gender.male': 'Hombre',
  'profile.gender.female': 'Mujer',
  'profile.gender.private': 'Privado',
  'profile.savedCount': 'Planes guardados',
  'profile.savingsCount': 'Metas de ahorro',
  'profile.saved': 'Planes guardados',
  'profile.settings': 'Preferencias',
  'profile.data': 'Datos',
  'profile.aboutUs': 'Sobre nosotros',
  'profile.about': 'Política de privacidad',

  'saved.title': 'Planes guardados',
  'saved.empty': 'Aún no hay planes. Calcula y guarda uno.',
  'saved.goCalc': 'Ir a calcular',
  'saved.fav': 'Favorito',
  'saved.unfav': 'Quitar favorito',
  'saved.compare': 'Comparar',
  'saved.leaveCompare': 'Salir de comparar',
  'saved.delete': 'Eliminar',
  'saved.deleteTitle': 'Eliminar plan',
  'saved.deleteConfirm': '¿Eliminar este plan guardado?',
  'saved.inCompare': 'En comparar',
  'saved.meta': 'Capital {principal} · {rate}% · {months} m',
  'saved.deleted': 'Eliminado',

  'settings.title': 'Preferencias',
  'settings.nickname': 'Apodo',
  'settings.avatar': 'Avatar',
  'settings.decimals': 'Decimales',
  'settings.language': 'Idioma',
  'settings.save': 'Guardar',
  'settings.defaultNick': 'Prestatario',

  'currency.label': 'Moneda',
  'currency.current': 'Ahora {symbol} {name}',
  'currency.pick': 'Elegir moneda',
  'currency.CNY': 'Yuan chino',
  'currency.USD': 'Dólar estadounidense',
  'currency.EUR': 'Euro',
  'currency.GBP': 'Libra esterlina',
  'currency.INR': 'Rupia india',
  'currency.JPY': 'Yen japonés',
  'currency.HKD': 'Dólar de Hong Kong',
  'currency.SGD': 'Dólar de Singapur',
  'currency.AUD': 'Dólar australiano',
  'currency.CAD': 'Dólar canadiense',
  'currency.KRW': 'Won surcoreano',
  'currency.THB': 'Baht tailandés',

  'data.title': 'Datos',
  'data.clear': 'Borrar planes y ahorro',
  'data.hint':
    'Solo borra planes y metas. Se mantienen apodo, moneda e idioma.',
  'data.confirm':
    '¿Borrar todos los cálculos y el ahorro? Se conservan las preferencias.',
  'data.cleared': 'Datos de negocio borrados',

  'aboutUs.title': 'Sobre nosotros',
  'aboutUs.body':
    'Dedicado a quien se prepara para pedir un préstamo, ofrece un cálculo de cuotas que se puede revisar y una comparación de planes que se puede contrastar. Introduce importe, tasa anual y plazo para ver la cuota, los intereses totales y el importe total antes de solicitarlo.\n\nCubre hipoteca, auto, crédito personal y combinado. El combinado muestra las dos partes en paralelo, con capital, tasa y cuota, además del total conjunto. El de auto puede calcular el importe a partir del precio del vehículo y la entrada. Los métodos son cuota fija y capital fijo: el primero mantiene el mismo pago; el segundo empieza más alto y suele generar menos intereses.\n\nLa amortización detalla capital, intereses y capital pendiente de cada período. La comparación admite hasta 3 planes; con 2 ya se contrastan los intereses totales y la cuota. La meta de ahorro puede rellenarse con unas 3 cuotas y registrar después ingresos y retiros.\n\nLa interfaz está en English y Español. Los importes pueden mostrarse con símbolos de monedas habituales. Cambiar de moneda solo ajusta el símbolo y los decimales; los importes guardados no se convierten por tipo de cambio. Los planes pueden guardarse en Perfil para abrirlos de nuevo y marcarse como favoritos.',
  'about.title': 'Política de privacidad',

  'toast.savedProfile': 'Guardado en Perfil',
  'toast.alreadySaved': 'Este plan ya está guardado',
  'common.back': 'Atrás',
  'common.missing': 'No encontrado',
  'splash.subtitle': 'Cálculo al instante · Privado en el dispositivo · Ahorro',
  'savings.fab': 'Nueva meta de ahorro',
  'savings.detailTitle': 'Detalle de ahorro',
  'savings.newTitle': 'Nuevo ahorro',
  'tag.label': 'Etiquetas',
  'tag.custom': 'Etiqueta personalizada, Enter para añadir',
  'tag.add': 'Añadir',
  'tag.needOne': 'Elige al menos una etiqueta para filtrar',
  'tag.remove': 'Quitar {name}',
  'tag.all': 'Todas',
  'tag.calcBadge': 'Cálculo',
  'tag.mortgage': 'Hipoteca',
  'tag.auto': 'Auto',
  'tag.consumer': 'Consumo',
  'tag.payment': 'Cuota',
  'tag.insurance': 'Seguro',
  'tag.reno': 'Reforma',
  'tag.edu': 'Educación',
  'tag.medical': 'Salud',
  'tag.daily': 'Diario',
  'tag.other': 'Otro',
  'seed.mortgageNote': 'Plan de hipoteca de ejemplo',
  'seed.autoNote': 'Plan de auto de ejemplo',
  'seed.savingsName': 'Colchón de cuota de ejemplo',
};

const TABLES: Record<AppLocale, Record<MessageKey, string>> = {
  en,
  es,
};

export function isAppLocale(value: unknown): value is AppLocale {
  return value === 'en' || value === 'es';
}

export function translate(
  locale: AppLocale,
  key: MessageKey,
  vars?: Record<string, string | number>,
): string {
  const table = TABLES[locale] ?? TABLES.en;
  let text = table[key] ?? TABLES.en[key] ?? String(key);
  if (vars) {
    for (const [k, v] of Object.entries(vars)) {
      text = text.split(`{${k}}`).join(String(v));
    }
  }
  return text;
}

export type TranslateFn = (
  key: MessageKey,
  vars?: Record<string, string | number>,
) => string;

export function categoryMessageKey(
  category: 'mortgage' | 'auto' | 'personal' | 'dual' | 'other',
): MessageKey {
  if (category === 'mortgage') return 'cat.mortgage';
  if (category === 'auto') return 'cat.auto';
  if (category === 'personal') return 'cat.personal';
  if (category === 'dual') return 'cat.dual';
  return 'cat.other';
}

export function modeMessageKey(
  mode: 'equal-payment' | 'equal-principal',
): MessageKey {
  return mode === 'equal-payment' ? 'mode.equalPayment' : 'mode.equalPrincipal';
}

export function currencyNameKey(code: string): MessageKey | null {
  const key = `currency.${code}` as MessageKey;
  return key in en ? key : null;
}

export function htmlLang(locale: AppLocale): string {
  if (locale === 'es') return 'es';
  return 'en';
}

/** Default nicknames. A stored default follows the current language. */
export const DEFAULT_NICKNAMES = ['Borrower', 'Prestatario'] as const;

export function isDefaultNickname(nickname: string): boolean {
  const n = nickname.trim();
  return (DEFAULT_NICKNAMES as readonly string[]).includes(n) || n === '';
}

export function displayNickname(nickname: string, t: TranslateFn): string {
  return isDefaultNickname(nickname) ? t('settings.defaultNick') : nickname;
}

/** Default name for a new goal. Display follows the current language. */
export const DEFAULT_SAVINGS_NAMES = [
  'Payment buffer',
  'Colchón de cuota',
] as const;

/** The first sample goal written on a fresh install. */
export const EXAMPLE_SAVINGS_NAMES = [
  'Sample payment buffer',
  'Colchón de cuota de ejemplo',
] as const;

export function isDefaultSavingsName(name: string): boolean {
  return (DEFAULT_SAVINGS_NAMES as readonly string[]).includes(name.trim());
}

export function isExampleSavingsName(name: string): boolean {
  return (EXAMPLE_SAVINGS_NAMES as readonly string[]).includes(name.trim());
}

export function displaySavingsName(name: string, t: TranslateFn): string {
  if (isExampleSavingsName(name)) return t('seed.savingsName');
  return isDefaultSavingsName(name) ? t('savings.defaultName') : name;
}

const KNOWN_COPY: Record<string, MessageKey> = {
  'Sample mortgage plan': 'seed.mortgageNote',
  'Sample auto plan': 'seed.autoNote',
  'Plan de hipoteca de ejemplo': 'seed.mortgageNote',
  'Plan de auto de ejemplo': 'seed.autoNote',
};

/** Seed plan names follow the current language. Text the user wrote stays as typed. */
export function displayKnownCopy(text: string, t: TranslateFn): string {
  const key = KNOWN_COPY[text.trim()];
  return key ? t(key) : text;
}
