//Get value of checkbox widgets
function $CB(cb_id){
	if ($(cb_id).checked) {return "Y";}
}
//Get value of check_box_group widgets
function $CF(cb_class){
	return $$(cb_class).findAll(function(cb) {return cb.checked}).pluck("value");
}
//Get value of check_box_group_followup widgets
function $CBFG(followup_id){
	cur_idx_values = new Hash();
	$$('.'+followup_id).each(function(s) {
		var the_value = s.value;
		var value_string = "";
		if (s.checked) {
			$$('#' + followup_id + '_' + the_value + ' input').each(function(c){if (c.checked) {value_string = value_string + c.value}});
			cur_idx_values.set(the_value,value_string);	
		}	
	});
	//console.log(followup_id+':  '+cur_idx_values.inspect());
	return cur_idx_values;
}
//Get value of radiobutton widgets
function $RF(rb_class){
	var chosen_element = $$(rb_class).find(function(rb){return rb.checked});
	return (chosen_element != null) ? chosen_element.value : null;
}
//Get value of date and month_year widgets
function $DF(name){
	var yield_field = $F(name+'_year');
	var year = yield_field.length > 0 ? (new Date).getFullYear().toString().substring(0,4-yield_field.length) + yield_field : "";
	var d = new Date($F(name+'_month') + "/" + $F(name+'_day')  + "/" + year);
	return (d == "Invalid Date") ? null : d;
}
//Get value of date_time widgets
function $DTF(name){
	var yield_field = $F(name+'_year');
	var year = yield_field.length > 0 ? (new Date).getFullYear().toString().substring(0,4-yield_field.length) + yield_field : "";
	var hours = parseInt($F(name+'_hours'));
	if (isNaN(hours)) {return null};
	if ($F(name+'_am_pm') == 'pm') {hours = hours + 12};
	var minutes = parseInt($F(name+'_minutes'));
	if (isNaN(minutes)) {return null};
	var d = new Date($F(name+'_month') + "/" + $F(name+'_day')  + "/" + year + " "+ hours + ':' + minutes);
	return (d == "Invalid Date") ? null : d;
}
//Get value of time widgets
function $TF(name){
	var hours = $F(name+'_hours');
	var minutes = $F(name+'_minutes');
	if (/[^\d]/.exec(hours) || /[^\d]/.exec(minutes)) {
		return null
	}
	var hours = parseInt(hours);
	if (isNaN(hours) || hours > 12 || hours < 1) {return null};
	var minutes = parseInt(minutes);
	if (isNaN(minutes) || minutes > 59 || minutes < 0) {return null};
	var d = new Date("1/1/1 "+ hours + ':' + minutes + ' ' + $F(name+'_am_pm'));
	return (d == "Invalid Date") ? null : d;
}
//Get value of factor_textfield widgets
function $FTF(name){
    var first_box = parseFloat($F(name+'_first_box'));
    var second_box = parseFloat($F(name+'_second_box'));
	if (isNaN(first_box)) {first_box=0};
	if (isNaN(second_box)) {second_box=0};
	//console.log(first_box * parseFloat($F(name+'_factor')) + second_box);
	return first_box * parseFloat($F(name+'_factor')) + second_box;
}
//Get value of time_interval_with_days widgets
function $TIWDF(name){
    var days = parseFloat($F(name+'_days'));
    var hours = parseFloat($F(name+'_hours'));
    var minutes = parseFloat($F(name+'_minutes'));
	if (isNaN(days)) {days=0};
	if (isNaN(hours)) {hours=0};
	if (isNaN(minutes)) {minutes=0};
	return (days * 1440) + (hours * 60) + minutes;
}
//Get value of time_interval widgets
function $TIF(name){
    var hours = parseFloat($F(name+'_hours'));
    var minutes = parseFloat($F(name+'_minutes'));
	if (isNaN(hours)) {hours=0};
	if (isNaN(minutes)) {minutes=0};
	return hours * 60 + minutes;
}

function getRadioGroupValue(radioGroupName,form) {
	var checked_element = form.getInputs('radio', radioGroupName).find(function(re) {return re.checked;});
	return (checked_element != null) ? $F(checked_element) : null;
}

function getCheckboxGroupValue(checkboxGroupName,form) {
	return form.getInputs("checkbox").findAll(
		function(item) { 
			if (item.name.indexOf(checkboxGroupName) === 0) {
				return item.checked; 
			}
	}).pluck("value");
}

function setCheckboxGroup(checkboxGroupName,form,value) {
	form.getInputs("checkbox").findAll(function(item)
	{ if (item.name.indexOf(checkboxGroupName) === 0) {
		item.checked = value;
	} });
}

function includes(cur_val,str) {
	result = false;
	str.split(',').each(function(s) {
	 	if(result) {return};
		if(Object.isArray(cur_val)){
			if(cur_val.include(s)){result=true};
		}
		if(Object.isHash(cur_val)){
			if(cur_val.keys().include(s)){result=true};
		}
		})
	return result;
}


function submitAndRedirect(url)
{
	if ($('metaForm') && $('meta_force_read_only') == null) {
		$('_redirect_url').value = url;
		$('metaForm').submit();
		return false;
	}
	else {
		location.href = url;
		return false;
	}
}

var indexedItems = Class.create();
indexedItems.prototype = {
	elem_id: 'indexed_presentation',
	self_name: 'i',
	delete_text: 'Delete an item',
	initialize: function () {
		},
	addItem: function(item) {
		var items = $(this.elem_id).childElements();
		var element = new Element('li', {'class':'presentation_indexed_item',style:'display:none'});
		var presentation = this;
		element.innerHTML = item;
		var other_element = new Element('input',{type:'button',value:this.delete_text,'class':'float_right'});
		other_element.onclick = function (evt) {
				presentation.removeItem($(this).up());
			};
		$(element).appendChild(other_element);
		$(element).appendChild(Element('div', {'class':'clear'}));
		$(this.elem_id).appendChild(element);
		Effect.toggle(element,'blind',{duration: .3});
	},
	removeItem: function(item) {
		Effect.toggle(item,'blind',{duration: .5, afterFinish: myCallBackOnFinish});
	}

};

function myCallBackOnFinish(obj){
	var item = obj.element.remove();
}

function regexMatch(value,regex,opts) {
	options = opts || new Hash(); 
	var result = false;
	//console.log('value ='+value.inspect());
	//console.log("options.get('idx') = "+options.get('idx'));
	if(options.get('idx') != undefined){
		//console("value[options.get('idx')] = "+value[options.get('idx')].inspect());
		val_to_check = new Array(value[options.get('idx')]);}
	else{
		if(Object.isString(value)){
			val_to_check = new Array(value)
		}else{
			val_to_check = value};
		}
	//console.log('val_to_check ='+val_to_check.inspect());
    if(!val_to_check){return false};
	val_to_check.each(function(cur_val) {
		if(result){return};
		if(typeof(cur_val) == "string") {
			if(cur_val.match(regex)) {result=true}
		} else {
			if(Object.isHash(cur_val)) {
				if(options.get('match_keys')){
					//console.log("MATCH KEYS");
					array_to_check = cur_val.keys();}
				else if(options.get('only_key')){
					//console.log("ONLY KEY");
					if(!cur_val.get(options.get('only_key'))){return};
					array_to_check = new Array(cur_val.get(options.get('only_key')))}
				else{
					array_to_check = cur_val.values();}
			} else if(Object.isArray(cur_val)) {
				array_to_check = cur_val
			}
	           if(!array_to_check){return};			
				array_to_check.each(function(val) {
					if(val.match(regex)) {result=true;}
			});
		}
	});
	//console.log('result:  '+result);
	return result;
}

function insert_tabs(tab_html,anchor_css,before_anchor,default_anchor_css,desired_tab_num,multi) {
	next_tabs = $$(anchor_css);
	// If your anchor tab isn't there, then put the tab before the default tab.  
	//If that's not there, use the last tab in the group.
	if (next_tabs.length == 0){
		before_anchor = true;
		next_tabs = $$(default_anchor_css);
		if (next_tabs.length == 0) {
			$$(".tabs ul").each(function(tab_ul) {
		  		next_tabs.push(tab_ul.childElements().last());
			});
		}
	}
	current_tab_num = 0;
	while (current_tab_num < desired_tab_num) {
		this_tab_html = tab_html;
		current_tab_num = current_tab_num + 1;
		if (multi) {
			display_num = current_tab_num + 1;
			this_tab_html = this_tab_html.gsub(/NUM/,' '+display_num).gsub(/INDEX/,display_num-1);
		}
		before_anchor ? next_tabs.invoke('insert',{before:  this_tab_html}) : next_tabs.invoke('insert',{after:  this_tab_html});
		
	}
}

function find_current_idx() {
	cur_idx = location.href.split('/').pop();
	if (!cur_idx.match(/\d/)) {cur_idx = 0};
	return cur_idx;
}
function update_date(write_date,read_date) {
	$('record_'+write_date+'_am_pm').value = $F('record_'+read_date+'_am_pm');
	$('record_'+write_date+'_month').value = $F('record_'+read_date+'_month');
	$('record_'+write_date+'_day').value = $F('record_'+read_date+'_day');
	$('record_'+write_date+'_year').value = $F('record_'+read_date+'_year');
}

function date_time_invalid(field_id) {
	if ($F(field_id+'_year') == '' && $F(field_id+'_month') == '' && $F(field_id+'_day') == '' && $F(field_id+'_hours') == '' && $F(field_id+'_minutes') == '') {
		return false;
	}
	return $DTF(field_id) == null;
}

function date_invalid(field_id) {
	if ($F(field_id+'_year') == '' && $F(field_id+'_month') == '' && $F(field_id+'_day') == '') {
		return false;
	}
	return $DF(field_id) == null;
}

function time_invalid(field_id) {
	if ($F(field_id+'_hours') == '' && $F(field_id+'_minutes') == '') {
		return false;
	}
	return $TF(field_id) == null;
}

function mark_field_validity(field_id,is_invalid,invalid_text) {
	var the_style;
	var wrapper = $(field_id+'_wrapper');
	var title = wrapper.title;
	if (title == 'undefined') {title = ""};
	title = title.gsub(invalid_text,"");
	if (is_invalid) {
		the_style = "background-color: #FFCCFF;padding: 3px; border-style: solid;border-width: 2px 2px 2px 2px; border-color: #CC0033;";
		if (title.length > 0) {
			title = title + "; "
		}
		wrapper.title = title + invalid_text;
	}
	else {
		the_style = "background-color: white; border-style: none;padding: 0px;";
		wrapper.title = title;
	}
	wrapper.setStyle(the_style);
}

function mark_invalid_date_time(field_id) {
	mark_field_validity(field_id,date_time_invalid(field_id),"Invalid date-time")
}

function mark_invalid_date(field_id) {
	mark_field_validity(field_id,date_invalid(field_id),"Invalid date")
}

function mark_invalid_time(field_id) {
	mark_field_validity(field_id,time_invalid(field_id),"Invalid time")
}

function confirmReset() {
	if (confirm("Are you sure you want to revert the information on this page to what it was when you last loaded the page?")) {window.location.reload()}
}

var field_length=0;
function tabNext(obj,event,len,next_field){
if(event=="down"){field_length=obj.value.length;}
else if(event=="up"){
if(obj.value.length!=field_length){
field_length=obj.value.length;
if(field_length==len){next_field.focus();}}}}