'use strict';
'require view';
'require fs';
'require form';
'require ui';
'require uci';

function renderState(state) {
	const spanTemp = '<span style="color:%s"><strong>%s</strong></span>';

	if (state == 'manual')
		return String.format(spanTemp, 'green', _('MANUAL ACTIVE'));
	if (state == 'auto')
		return String.format(spanTemp, 'green', _('AUTO ACTIVE'));
	if (state == 'mixed')
		return String.format(spanTemp, 'green', _('MIXED ACTIVE'));

	return String.format(spanTemp, 'red', _('NOT RUNNING'));
}

return view.extend({
	load() {
		return L.resolveDefault(fs.read_direct('/proc/interrupts'));
	},

	render(data) {
		let s, o;
		const cpuNum = data ? data.match(/\bCPU\d+\b/g).map(i => i.slice(3)) : [],
		      irqNum = data ? data.match(/\b\d+(?=: )/g) : [];

		/* single map; the daemon options live in the irqbalance UCI file via
		 * uciconfig but render as just another tab */
		const m = new form.Map('smartwrt-irq', _('SmartWrt IRQ'), _('Assigns network device IRQs to specific CPUs so that wired traffic and Wi-Fi stay inside their own cache domains. Placement is derived from the hardware cache topology; the configuration only overrides it.'));
		m.parsechain = ['smartwrt-irq', 'irqbalance'];

		s = m.section(form.NamedSection);
		s.anonymous = true;
		s.render = function () {
			const mode = uci.get('smartwrt-irq', 'policy', 'mode');
			const active = mode == 'manual' || mode == 'auto' || mode == 'mixed';

			return E('div', { class: 'cbi-section' },
				E('p', { id: 'status' }, renderState(active ? mode : null)));
		}

		s = m.section(form.NamedSection, 'policy', 'irq', _('IRQ Snapshot'));
		s.render = function () {
			const snapshot = new ui.Textarea(data ? data.slice(0, -1) : '', {
				readonly: true,
				placeholder: _('Loading...'),
				monospace: true,
				rows: data ? data.split('\n').length - 1 : 10,
			});
			return snapshot.render();
		}

		s = m.section(form.NamedSection, 'policy', 'irq', _('Settings'));
		s.description = _('Auto hands the IRQs to irqbalance (see the Auto Settings tab).') + '<br />' + _('Manual assigns each discovered IRQ to a fixed CPU (see the Manual Settings tab) and stops irqbalance.') + '<br />' + _('Mixed pins the network IRQs like Manual and lets irqbalance handle everything else.') + '<br />' + _('Off leaves everything to the kernel.');

		s.tab('general', _('General Settings'));
		s.tab('manual', _('Manual Settings'), _('Applied in Modes Manual and Mixed: assigns each discovered IRQ to a fixed CPU.'));
		s.tab('auto', _('Auto Settings'), _('Settings for the daemon that takes over in Modes Auto and Mixed. The daemon\'s enabled state is managed by smartwrt-irq according to the selected mode.'));

		o = s.taboption('general', form.ListValue, 'mode', _('Mode'));
		o.value('auto', _('Auto'));
		o.value('manual', _('Manual'));
		o.value('mixed', _('Mixed'));
		o.value('off', _('Off'));
		o.default = 'manual';

		o = s.taboption('manual', form.Value, 'eth_pattern', _('Ethernet pattern'), _('Interrupt label pattern for the wired path. Empty means "eth".'));
		o.placeholder = 'eth';
		o.optional = true;

		o = s.taboption('manual', form.Value, 'wifi_pattern', _('Wi-Fi pattern'), _('Optional interrupt label pattern to override phy-based radio discovery.'));
		o.optional = true;

		o = s.taboption('manual', form.Value, 'eth_cpu', _('Ethernet CPU'), _('CPU for the wired IRQs. Empty means the first CPU of the first cache group.') + '<br />' + _('Valid values: %s.').format(cpuNum.join(', ')));
		o.placeholder = '';
		o.optional = true;
		o.validate = function (section_id, value) {
			if (value == '')
				return true;
			for (const i of value.split(/[\s,-]+/))
				if (i != '' && !cpuNum.includes(i))
					return _('Invalid');
			return true;
		}

		o = s.taboption('manual', form.Value, 'wifi_cpu', _('Wi-Fi CPUs'), _('CPUs for the radios, assigned round-robin. Empty means automatic: one free cache group per radio when possible.') + '<br />' + _('Comma-separated list, e.g. %s.').format(cpuNum.join(',')) + '<br />' + _('Valid values: %s.').format(cpuNum.join(', ')));
		o.placeholder = '';
		o.optional = true;
		o.validate = function (section_id, value) {
			if (value == null || value == '')
				return true;
			for (const i of value.split(/[\s,-]+/))
				if (i != '' && !cpuNum.includes(i))
					return _('Invalid');
			return true;
		}

		o = s.taboption('manual', form.Flag, 'on_reload', _('Re-apply on reload'), _('Re-apply placement after network or Wi-Fi reloads.'));
		o.default = '1';

		o = s.taboption('manual', form.Value, 'timeout', _('Timeout'), _('Seconds to wait for the radio IRQs during boot.'));
		o.placeholder = '30';
		o.datatype = 'uinteger';
		o.optional = true;

		o = s.taboption('general', form.Flag, 'debug', _('Show debug output'), _('Log decisions at debug level in the system log. Unchecked means silent.'));
		o.default = '0';

		/* options below carry uciconfig to read/write the irqbalance UCI file */

		o = s.taboption('auto', form.Value, 'deepestcache', _('Deepest cache'), _('Cache level at which irqbalance partitions cache domains.'));
		o.uciconfig = 'irqbalance';
		o.placeholder = '2';
		o.datatype = 'uinteger';
		o.optional = true;

		o = s.taboption('auto', form.Value, 'interval', _('Interval'), _('Value in seconds.'));
		o.placeholder = '10';
		o.datatype = 'uinteger';
		o.optional = true;

		o = s.taboption('auto', form.Value, 'banned_cpulist', _('Exclude CPUs'), _('List of CPUs to ignore, can be an integer or integers separated by commas.') + '<br />' + _('Valid values: %s.').format(cpuNum.join(', ')));
		o.placeholder = '';
		o.optional = true;
		o.validate = function (section_id, value) {
			if (value == '')
				return true;
			for (const i of value.split(','))
				if (i.trim() != '' && !cpuNum.includes(i.trim()))
					return _('Invalid');
			return true;
		}

		o = s.taboption('auto', form.DynamicList, 'banirq', _('Exclude IRQs'), _('List of IRQs to ignore.') + '<br />' + _('Valid values: %s.').format(irqNum.join(', ')));
		o.placeholder = '';
		o.datatype = 'uinteger';
		o.optional = true;
		o.validate = function (section_id, value) {
			if (value == null)
				return true;
			for (const i of value)
				if (i != '' && !irqNum.includes(i))
					return _('Invalid');
			return true;
		}

	/* attribution note at the bottom of the Auto tab */

		o = s.taboption('auto', form.DummyValue, '_attribution');
		o.render = function () {
			return E('div', { class: 'cbi-section-descr', style: 'text-align:left;' }, [
				_('This mode relies on the irqbalance daemon, which is Copyright (C) Intel and other contributors of the irqbalance project, distributed under the GNU General Public License, version 2.'),
				E('br'),
				_('SmartWrt thanks the project and its contributors for making this work possible.'),
				E('br'),
				_('More information at'), ' ', E('a', { href: 'https://github.com/irqbalance/irqbalance', target: '_blank', rel: 'noopener' }, 'https://github.com/irqbalance/irqbalance'), '.'
			]);
		}

		return m.render();
	}
});
