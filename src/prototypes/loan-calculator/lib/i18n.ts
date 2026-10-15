import type { AppLocale } from './types';

export type { AppLocale };

export const APP_LOCALES: {
  id: AppLocale;
  nativeLabel: string;
}[] = [
  { id: 'zh-CN', nativeLabel: '简体中文' },
  { id: 'en', nativeLabel: 'English' },
  { id: 'es', nativeLabel: 'Español' },
];

export type MessageKey = keyof typeof zhCN;

const zhCN = {
  'tab.calc': '计算',
  'tab.savings': '储蓄',
  'tab.profile': '我的',
  'nav.main': '主导航',
  'nav.back': '返回',

  'cat.mortgage': '房贷',
  'cat.auto': '车贷',
  'cat.personal': '消费',
  'cat.dual': '组合贷',
  'cat.other': '其他',
  'dual.partA': '贷款 A',
  'dual.partB': '贷款 B',
  'dual.combinedMonthly': '合计月供',
  'dual.combinedFirst': '合计首月',
  'dual.partBreakdown': '分笔明细',
  'dual.insight': '两笔合计月供约 {monthly}，总利息约 {interest}，总成本约 {total}。',
  'dual.params': '组合贷参数',
  'home.subtitle': '房贷 · 车贷 · 消费贷 · 组合贷 · 对比',

  'mode.equalPayment': '等额本息',
  'mode.equalPrincipal': '等额本金',

  'home.title': '贷款计算器',
  'home.badge.local': '数据在本地',
  'home.badge.saved': '已存 {count} 条',
  'home.loanType': '贷款类型',
  'home.repayMode': '还款方式',
  'home.params': '贷款参数',
  'home.paramsAuto': '车贷参数',
  'home.preview': '实时摘要 · {mode}',
  'home.previewDown': ' · 首付 {pct}%',
  'home.totalInterest': '总利息',
  'home.totalPayment': '还款总额',
  'home.principal': '贷款本金',
  'home.vehiclePrice': '车辆价格',
  'home.downPct': '首付比例',
  'home.downAmount': '首付金额',
  'home.loanAmount': '贷款金额',
  'home.loanHint': '默认 = 车价 − 首付；可手动改贷款额',
  'home.rate': '年利率',
  'home.term': '贷款期限',
  'home.year': '年',
  'home.month': '月',
  'home.yearsN': '{n} 年',
  'home.wan': '{n} 万',
  'home.million': '{n} 百万',
  'home.feature.ratio': '本息占比',
  'home.feature.amort': '摊还明细',
  'home.feature.compare': '方案对比',
  'home.cta': '开始计算',
  'home.disclaimer': '试算结果仅供参考，不构成任何放贷承诺',
  'home.unit.yuan': '元',
  'home.fillFirst': '请先填完整贷款参数',

  'result.title': '计算结果',
  'result.monthly': '月供',
  'result.firstLast': '首月 → 末月还款',
  'result.principal': '本金',
  'result.interest': '利息',
  'result.interestShare': '利息占比',
  'result.totalPayment': '还款总额',
  'result.totalInterest': '总利息',
  'result.loanPrincipal': '贷款本金',
  'result.vehicle': '车辆价格',
  'result.downPayment': '首付',
  'result.insights': '结果解读',
  'result.amort': '查看摊还明细',
  'result.compare': '加入对比',
  'result.save': '保存方案',
  'result.savings': '为月供设储蓄目标',
  'result.insight.1': '按{mode}，约 {years} 年还清，利息约占还款总额的 {share}%。',
  'result.insight.2': '月供约 {monthly} 元时，总利息约 {interest} 元。',
  'result.insight.3': '本金 {principal} 元，年利率 {rate}%。',
  'result.insight.auto':
    '车价 {vehicle} 元，首付 {pct}%（{down} 元），贷款 {principal} 元。',

  'amort.title': '摊还明细',
  'amort.periods': '共 {n} 期',
  'amort.byMonth': '按月',
  'amort.byYear': '按年',
  'amort.byCustom': '自定义',
  'amort.fromPeriod': '起始期',
  'amort.toPeriod': '结束期',
  'amort.rangeHint': '按期数筛选，范围 1～{max}',
  'amort.showing': '当前显示 {n} 期',
  'amort.rangeSum': '区间合计',
  'amort.col.period': '期',
  'amort.col.year': '年',
  'amort.col.payment': '还款',
  'amort.col.principal': '本金',
  'amort.col.interest': '利息',
  'amort.col.balance': '余额',

  'compare.title': '方案对比',
  'compare.subtitle': '最多 3 个 · 已选 {n}',
  'compare.needTwo': '至少选择 2 个方案才能对比。可从已保存列表加入，或再算一笔后点「加入对比」。',
  'compare.goSaved': '去已保存方案',
  'compare.metric': '指标',
  'compare.remove': '移除',
  'compare.principal': '本金/贷款',
  'compare.rate': '利率',
  'compare.term': '期限',
  'compare.termMonths': '{n} 月',
  'compare.monthly': '月供',
  'compare.addSaved': '添加已保存方案',
  'compare.perMonth': '{amount}/月',
  'compare.hint': '当前结果页可点「加入对比」把最新试算纳入对比。',
  'compare.max': '对比最多 3 个方案',
  'compare.added': '已加入对比',

  'savings.title': '储蓄目标',
  'savings.subtitle': '为月供或缓冲金攒一笔',
  'savings.inProgress': '{n} 个进行中',
  'savings.empty': '还没有储蓄目标。可从计算结果一键创建，或手动新建。',
  'savings.new': '新建目标',
  'savings.savedTotal': '已存合计',
  'savings.targetTotal': '目标合计',
  'savings.linkedHint': '已关联 {n} 条贷款方案，可在计算结果页快速创建目标',
  'savings.insights': '智能提示',
  'savings.insightsFor': '{name} · 提示',
  'savings.create': '新建',
  'savings.name': '名称',
  'savings.target': '目标金额',
  'savings.createCta': '创建',
  'savings.defaultName': '月供缓冲金',
  'savings.depositWithdraw': '存入 / 取出',
  'savings.amount': '金额',
  'savings.deposit': '存入',
  'savings.withdraw': '取出',
  'savings.flow': '流水',
  'savings.noTx': '暂无记录',
  'savings.done': '已存',
  'savings.todo': '待存',
  'savings.progress': '完成度',
  'savings.created': '目标已创建',
  'savings.missing': '目标不存在',
  'savings.eta.done': '已达成目标',
  'savings.eta.start': '还差 {amount}，存入后可估算达标时间',
  'savings.eta.continue': '还差 {amount}，继续存入可更新预测',
  'savings.eta.long': '还差 {amount}，当前节奏偏慢',
  'savings.eta.soon': '还差 {amount}，约 1 个月达标',
  'savings.eta.months': '还差 {amount}，约 {months} 个月达标',
  'savings.buffer.intro': '建议预留 3～6 个月月供',
  'savings.buffer.noLink': '关联贷款方案后可查看月供缓冲',
  'savings.buffer.high': '已覆盖约 {months} 个月月供，高于建议',
  'savings.buffer.ok': '已覆盖约 {months} 个月月供，处于建议区间',
  'savings.buffer.low': '已覆盖约 {months} 个月月供，距 3 个月还差 {gap}',

  'profile.title': '我的',
  'profile.subtitle': '本地资料与已保存方案',
  'profile.localOnly': '数据仅保存在本设备',
  'profile.savedCount': '已保存方案',
  'profile.savingsCount': '储蓄目标',
  'profile.saved': '已保存方案',
  'profile.settings': '偏好设置',
  'profile.data': '数据管理',
  'profile.about': '关于与隐私',

  'saved.title': '已保存方案',
  'saved.count': '{n} 条',
  'saved.empty': '还没有保存的试算。去计算一笔并保存吧。',
  'saved.goCalc': '去计算',
  'saved.fav': '收藏',
  'saved.unfav': '取消收藏',
  'saved.compare': '对比',
  'saved.delete': '删除',
  'saved.inCompare': '对比中',
  'saved.meta': '本金 {principal} · {rate}% · {months} 月',
  'saved.deleted': '已删除',

  'settings.title': '偏好设置',
  'settings.nickname': '昵称',
  'settings.avatar': '头像（emoji）',
  'settings.decimals': '小数位',
  'settings.language': '界面语言',
  'settings.save': '保存',
  'settings.defaultNick': '借款人',

  'currency.label': '显示货币',
  'currency.current': '当前 {symbol} {name}',
  'currency.pick': '选择货币',
  'currency.CNY': '人民币',
  'currency.USD': '美元',
  'currency.EUR': '欧元',
  'currency.GBP': '英镑',
  'currency.INR': '印度卢比',
  'currency.JPY': '日元',
  'currency.HKD': '港币',
  'currency.SGD': '新元',
  'currency.AUD': '澳元',
  'currency.CAD': '加元',
  'currency.KRW': '韩元',
  'currency.THB': '泰铢',

  'data.title': '数据管理',
  'data.export': '导出 JSON 备份',
  'data.clear': '清空计算与储蓄数据',
  'data.hint': '清空仅删除贷款方案与储蓄目标，不会重置昵称、货币等偏好。',
  'data.confirm': '确定清空所有计算与储蓄数据？偏好设置将保留。',
  'data.cleared': '业务数据已清空',

  'about.title': '关于与隐私',
  'about.body':
    '本原型为贷款计算器演示：所有计算在浏览器内完成，数据写入本地存储。支持房贷、车贷与消费贷试算、摊还明细与多方案对比。设计参考 Revolut Mobile，仅供产品原型参考。',

  'toast.savedProfile': '已保存到「我的」',
  'toast.alreadySaved': '相同方案已保存，未重复添加',
  'common.back': '返回',
  'common.missing': '页面不存在',
} as const;

const en: Record<MessageKey, string> = {
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
  'dual.params': 'Dual loan details',

  'mode.equalPayment': 'Equal payment',
  'mode.equalPrincipal': 'Equal principal',

  'home.title': 'Loan calculator',
  'home.subtitle': 'Home · Auto · Personal · Dual · Compare',
  'home.badge.local': 'Stored on device',
  'home.badge.saved': '{count} saved',
  'home.loanType': 'Loan type',
  'home.repayMode': 'Repayment',
  'home.params': 'Loan details',
  'home.paramsAuto': 'Auto loan details',
  'home.preview': 'Live preview · {mode}',
  'home.previewDown': ' · Down {pct}%',
  'home.totalInterest': 'Total interest',
  'home.totalPayment': 'Total cost',
  'home.principal': 'Principal',
  'home.vehiclePrice': 'Vehicle price',
  'home.downPct': 'Down payment %',
  'home.downAmount': 'Down payment',
  'home.loanAmount': 'Loan amount',
  'home.loanHint': 'Default = price − down; you can edit the loan amount',
  'home.rate': 'Annual rate',
  'home.term': 'Term',
  'home.year': 'yr',
  'home.month': 'mo',
  'home.yearsN': '{n} yr',
  'home.wan': '{n}0k',
  'home.million': '{n}M',
  'home.feature.ratio': 'Split',
  'home.feature.amort': 'Schedule',
  'home.feature.compare': 'Compare',
  'home.cta': 'Calculate',
  'home.disclaimer': 'Estimates only — not a lending offer',
  'home.unit.yuan': '',
  'home.fillFirst': 'Please complete the loan fields first',

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
  'amort.showing': 'Showing {n} periods',
  'amort.rangeSum': 'Range total',
  'amort.col.period': '#',
  'amort.col.year': 'Yr',
  'amort.col.payment': 'Payment',
  'amort.col.principal': 'Principal',
  'amort.col.interest': 'Interest',
  'amort.col.balance': 'Balance',

  'compare.title': 'Compare',
  'compare.subtitle': 'Up to 3 · {n} selected',
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
  'compare.addSaved': 'Add a saved plan',
  'compare.perMonth': '{amount}/mo',
  'compare.hint': 'From Results, tap Add to compare to include the latest run.',
  'compare.max': 'Compare up to 3 plans',
  'compare.added': 'Added to compare',

  'savings.title': 'Savings goals',
  'savings.subtitle': 'Buffer for monthly payments',
  'savings.inProgress': '{n} active',
  'savings.empty': 'No goals yet. Create one from Results, or add manually.',
  'savings.new': 'New goal',
  'savings.savedTotal': 'Saved',
  'savings.targetTotal': 'Target',
  'savings.linkedHint': '{n} loan plans linked — create goals from Results',
  'savings.insights': 'Insights',
  'savings.insightsFor': '{name} · tips',
  'savings.create': 'New',
  'savings.name': 'Name',
  'savings.target': 'Target amount',
  'savings.createCta': 'Create',
  'savings.defaultName': 'Payment buffer',
  'savings.depositWithdraw': 'Deposit / withdraw',
  'savings.amount': 'Amount',
  'savings.deposit': 'Deposit',
  'savings.withdraw': 'Withdraw',
  'savings.flow': 'Activity',
  'savings.noTx': 'No activity yet',
  'savings.done': 'Saved',
  'savings.todo': 'Left',
  'savings.progress': 'Progress',
  'savings.created': 'Goal created',
  'savings.missing': 'Goal not found',
  'savings.eta.done': 'Goal reached',
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
  'profile.savedCount': 'Saved plans',
  'profile.savingsCount': 'Savings goals',
  'profile.saved': 'Saved plans',
  'profile.settings': 'Preferences',
  'profile.data': 'Data',
  'profile.about': 'About & privacy',

  'saved.title': 'Saved plans',
  'saved.count': '{n} plans',
  'saved.empty': 'No saved plans yet. Run a calculation and save it.',
  'saved.goCalc': 'Go calculate',
  'saved.fav': 'Favorite',
  'saved.unfav': 'Unfavorite',
  'saved.compare': 'Compare',
  'saved.delete': 'Delete',
  'saved.inCompare': 'In compare',
  'saved.meta': 'Principal {principal} · {rate}% · {months} mo',
  'saved.deleted': 'Deleted',

  'settings.title': 'Preferences',
  'settings.nickname': 'Nickname',
  'settings.avatar': 'Avatar (emoji)',
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
  'data.export': 'Export JSON backup',
  'data.clear': 'Clear plans & savings',
  'data.hint':
    'Clears loan plans and savings only. Nickname, currency, and language stay.',
  'data.confirm':
    'Clear all calculation and savings data? Preferences will be kept.',
  'data.cleared': 'Business data cleared',

  'about.title': 'About & privacy',
  'about.body':
    'This prototype runs loan math in the browser and stores data locally. It covers home, auto, and personal loans, amortization, and plan compare. Visuals follow Revolut Mobile for product reference only.',

  'toast.savedProfile': 'Saved to Profile',
  'toast.alreadySaved': 'This plan is already saved',
  'common.back': 'Back',
  'common.missing': 'Not found',
};

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
  'dual.params': 'Datos del doble préstamo',

  'mode.equalPayment': 'Cuota fija',
  'mode.equalPrincipal': 'Capital fijo',

  'home.title': 'Calculadora de préstamos',
  'home.subtitle': 'Hipoteca · Auto · Personal · Doble · Comparar',
  'home.badge.local': 'Datos en el dispositivo',
  'home.badge.saved': '{count} guardados',
  'home.loanType': 'Tipo de préstamo',
  'home.repayMode': 'Amortización',
  'home.params': 'Datos del préstamo',
  'home.paramsAuto': 'Datos del auto',
  'home.preview': 'Vista previa · {mode}',
  'home.previewDown': ' · Entrada {pct}%',
  'home.totalInterest': 'Interés total',
  'home.totalPayment': 'Costo total',
  'home.principal': 'Capital',
  'home.vehiclePrice': 'Precio del vehículo',
  'home.downPct': '% de entrada',
  'home.downAmount': 'Entrada',
  'home.loanAmount': 'Importe del préstamo',
  'home.loanHint': 'Por defecto = precio − entrada; puedes editar el préstamo',
  'home.rate': 'Tasa anual',
  'home.term': 'Plazo',
  'home.year': 'a',
  'home.month': 'm',
  'home.yearsN': '{n} a',
  'home.wan': '{n}0 mil',
  'home.million': '{n}M',
  'home.feature.ratio': 'Reparto',
  'home.feature.amort': 'Tabla',
  'home.feature.compare': 'Comparar',
  'home.cta': 'Calcular',
  'home.disclaimer': 'Solo estimación — no es una oferta de crédito',
  'home.unit.yuan': '',
  'home.fillFirst': 'Completa los campos del préstamo',

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
  'amort.showing': 'Mostrando {n} periodos',
  'amort.rangeSum': 'Total del rango',
  'amort.col.period': '#',
  'amort.col.year': 'Año',
  'amort.col.payment': 'Cuota',
  'amort.col.principal': 'Capital',
  'amort.col.interest': 'Interés',
  'amort.col.balance': 'Saldo',

  'compare.title': 'Comparar',
  'compare.subtitle': 'Máx. 3 · {n} elegidos',
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
  'compare.addSaved': 'Añadir plan guardado',
  'compare.perMonth': '{amount}/mes',
  'compare.hint': 'En Resultados, pulsa Añadir a comparar para incluir el último cálculo.',
  'compare.max': 'Máximo 3 planes',
  'compare.added': 'Añadido a comparar',

  'savings.title': 'Metas de ahorro',
  'savings.subtitle': 'Colchón para la cuota',
  'savings.inProgress': '{n} activas',
  'savings.empty': 'Aún no hay metas. Créalas desde Resultados o manualmente.',
  'savings.new': 'Nueva meta',
  'savings.savedTotal': 'Ahorrado',
  'savings.targetTotal': 'Objetivo',
  'savings.linkedHint': '{n} planes vinculados — crea metas desde Resultados',
  'savings.insights': 'Ideas',
  'savings.insightsFor': '{name} · ideas',
  'savings.create': 'Nueva',
  'savings.name': 'Nombre',
  'savings.target': 'Importe objetivo',
  'savings.createCta': 'Crear',
  'savings.defaultName': 'Colchón de cuota',
  'savings.depositWithdraw': 'Ingresar / retirar',
  'savings.amount': 'Importe',
  'savings.deposit': 'Ingresar',
  'savings.withdraw': 'Retirar',
  'savings.flow': 'Movimientos',
  'savings.noTx': 'Sin movimientos',
  'savings.done': 'Ahorrado',
  'savings.todo': 'Falta',
  'savings.progress': 'Progreso',
  'savings.created': 'Meta creada',
  'savings.missing': 'Meta no encontrada',
  'savings.eta.done': 'Meta alcanzada',
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
  'profile.savedCount': 'Planes guardados',
  'profile.savingsCount': 'Metas de ahorro',
  'profile.saved': 'Planes guardados',
  'profile.settings': 'Preferencias',
  'profile.data': 'Datos',
  'profile.about': 'Acerca de y privacidad',

  'saved.title': 'Planes guardados',
  'saved.count': '{n} planes',
  'saved.empty': 'Aún no hay planes. Calcula y guarda uno.',
  'saved.goCalc': 'Ir a calcular',
  'saved.fav': 'Favorito',
  'saved.unfav': 'Quitar favorito',
  'saved.compare': 'Comparar',
  'saved.delete': 'Eliminar',
  'saved.inCompare': 'En comparar',
  'saved.meta': 'Capital {principal} · {rate}% · {months} m',
  'saved.deleted': 'Eliminado',

  'settings.title': 'Preferencias',
  'settings.nickname': 'Apodo',
  'settings.avatar': 'Avatar (emoji)',
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
  'data.export': 'Exportar JSON',
  'data.clear': 'Borrar planes y ahorro',
  'data.hint':
    'Solo borra planes y metas. Se mantienen apodo, moneda e idioma.',
  'data.confirm':
    '¿Borrar todos los cálculos y el ahorro? Se conservan las preferencias.',
  'data.cleared': 'Datos de negocio borrados',

  'about.title': 'Acerca de y privacidad',
  'about.body':
    'Este prototipo calcula préstamos en el navegador y guarda datos en local. Incluye hipoteca, auto, personal, amortización y comparación. La UI sigue Revolut Mobile solo como referencia de producto.',

  'toast.savedProfile': 'Guardado en Perfil',
  'toast.alreadySaved': 'Este plan ya está guardado',
  'common.back': 'Atrás',
  'common.missing': 'No encontrado',
};

const TABLES: Record<AppLocale, Record<MessageKey, string>> = {
  'zh-CN': zhCN,
  en,
  es,
};

export function isAppLocale(value: unknown): value is AppLocale {
  return value === 'zh-CN' || value === 'en' || value === 'es';
}

export function translate(
  locale: AppLocale,
  key: MessageKey,
  vars?: Record<string, string | number>,
): string {
  const table = TABLES[locale] ?? TABLES['zh-CN'];
  let text = table[key] ?? TABLES['zh-CN'][key] ?? String(key);
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
  return key in zhCN ? key : null;
}

export function htmlLang(locale: AppLocale): string {
  if (locale === 'zh-CN') return 'zh-CN';
  if (locale === 'es') return 'es';
  return 'en';
}

/** 各语言下的默认昵称；用于识别「仍是系统默认」从而随界面语言切换展示 */
export const DEFAULT_NICKNAMES = ['借款人', 'Borrower', 'Prestatario'] as const;

export function isDefaultNickname(nickname: string): boolean {
  const n = nickname.trim();
  return (DEFAULT_NICKNAMES as readonly string[]).includes(n) || n === '';
}

export function displayNickname(nickname: string, t: TranslateFn): string {
  return isDefaultNickname(nickname) ? t('settings.defaultNick') : nickname;
}

/** 种子/默认储蓄目标名，随界面语言展示 */
export const DEFAULT_SAVINGS_NAMES = [
  '月供缓冲金',
  'Payment buffer',
  'Colchón de cuota',
] as const;

export function isDefaultSavingsName(name: string): boolean {
  return (DEFAULT_SAVINGS_NAMES as readonly string[]).includes(name.trim());
}

export function displaySavingsName(name: string, t: TranslateFn): string {
  return isDefaultSavingsName(name) ? t('savings.defaultName') : name;
}
