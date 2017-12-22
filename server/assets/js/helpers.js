
var saveButton, forkButton, parentButton, diffButton;
var effect_owner=false;
var original_code='';
var original_version='';

function initialize_compressor(){
	return null;
}

function initialize_helper() {
	window.onhashchange = function() { load_url_code(); };

	if (typeof localStorage !== 'undefined') {
		if ( !localStorage.getItem('glslsandbox_user') ) {
			localStorage.setItem('glslsandbox_user', generate_user_id());
		}
	} else {
		// This fallback shouldn't be used by any browsers that are able to commit code.
		localStorage = { getItem: function(x) { return 'invalid_user'; } };
	}
}
function initialize_compressor() {
	compressor=new LZMA( "js/lzma_worker.js" );
	return compressor;
}

function initialize_helper() {
}

function load_url_code() {
	if ( window.location.hash ) {

		var hash = window.location.hash.substr( 1 );
		var version = hash.substr( 0, 2 );

		if ( version == 'A/' ) {

			// LZMA

			readURL( hash.substr( 2 ) );

		} else {

			// Basic format

			code.value = decodeURIComponent( hash );

		}

	} else {

		readURL( '5d00000100b70200000000000000381c88cdaf8125d4569ed1e6e6c09c2fe72b7d489ad9d27ce026c1d90b38e6a986e7c482f98001c7d016ca8db7da32debe67fc602659f4e96ae150d75ea26ae8e8f4056e0b845d0814a2acee3a47ec45af66fb0405385eaedd50db968497c1cbbd79f0634d5534182b2093986dae5ac7e840eb137f39f5b27efbb488f4e85faa6f4c942182673e75dca44f7ffbd8c25c5a2763cb750b9b4e14b9fd5c15ca81ed7ef88a4f77a114cd2d7f675b6a05b467bd164f4058dd3250e6fcdc9d7c195dccdc63b304e1f8c7aaccb1edb7992aa1341e96aa6e8b1ca044e70207be752de1b41e4e07843ab895b2a1995b97085afff70f5eff9d2b630a4c5e43e7ce6f977616d57c97935342e48d0ee9ad3462804ae5608b6872b9749632bf8514fea3ebf9d64b10deb3ff041395050deffbf038e3' );

	}
}

function setURL( shaderString ) {

	compressor.compress( shaderString, 1, function( bytes ) {

		var hex = convertBytesToHex( bytes );
		window.location.replace( '#A/' + hex );

	},
	dummyFunction );

}

function readURL( hash ) {

	var bytes = convertHexToBytes( hash );

	compressor.decompress( bytes, function( text ) {

		compileOnChangeCode = false;  // Prevent compile timer start
		code.setValue(text);
		compile();
		compileOnChangeCode = true;

	},
	dummyFunction );

}

function convertHexToBytes( text ) {

	var tmpHex, array = [];

	for ( var i = 0; i < text.length; i += 2 ) {

		tmpHex = text.substring( i, i + 2 );
		array.push( parseInt( tmpHex, 16 ) );

	}

	return array;

}

function convertBytesToHex( byteArray ) {

	var tmpHex, hex = "";

	for ( var i = 0, il = byteArray.length; i < il; i ++ ) {

		if ( byteArray[ i ] < 0 ) {

			byteArray[ i ] = byteArray[ i ] + 256;

		}

		tmpHex = byteArray[ i ].toString( 16 );

		// add leading zero

		if ( tmpHex.length == 1 ) tmpHex = "0" + tmpHex;

		hex += tmpHex;

	}

	return hex;

}

// dummy functions for saveButton
function set_save_button(visibility) {
}

function set_parent_button(visibility) {
}

function add_server_buttons() {
}

function generate_user_id() {
	return (Math.random()*0x10000000|0).toString(16);
}

function get_user_id() {
	return localStorage.getItem('glslsandbox_user');
}

function am_i_owner() {
	return (effect_owner && effect_owner==get_user_id());
}

function load_url_code() {
	if ( window.location.hash!='') {

		load_code(window.location.hash.substr(1));

	} else {

		code.setValue(document.getElementById( 'example' ).text);
		original_code = document.getElementById( 'example' ).text;

	}
}

function add_server_buttons() {
	saveButton = document.createElement( 'button' );
	saveButton.style.visibility = 'hidden';
	saveButton.textContent = 'save';
	saveButton.addEventListener( 'click', save, false );
	toolbar.appendChild( saveButton );

	parentButton = document.createElement( 'a' );
	parentButton.style.visibility = 'hidden';
	parentButton.textContent = 'parent';
	parentButton.href = original_version;
	toolbar.appendChild( parentButton );

	diffButton = document.createElement( 'a' );
	diffButton.style.visibility = 'hidden';
	diffButton.textContent = 'diff';
	diffButton.href = '/';
	toolbar.appendChild( diffButton );

	set_parent_button('visible');
}

function set_save_button(visibility) {
	if(original_code==code.getValue())
		saveButton.style.visibility = 'hidden';
	else
		saveButton.style.visibility = visibility;
}

function set_parent_button(visibility) {
	if(original_version=='') {
		parentButton.style.visibility = 'hidden';
		diffButton.style.visibility = 'hidden';
	} else {
		parentButton.style.visibility = visibility;
		diffButton.style.visibility = visibility;
	}
}


function get_img( width, height ) {
	canvas.width = width;
	canvas.height = height;
	parameters.screenWidth = width;
	parameters.screenHeight = height;

	gl.viewport( 0, 0, width, height );
	createRenderTargets();
	resetSurface();

	render();

	img=canvas.toDataURL('image/png');

	onWindowResize();

	return img;
}

function save() {
	img=get_img(200, 100);

	data={
		"code": code.getValue(),
		"image": img,
		"user": get_user_id()
	}

	loc='/e';

	if(am_i_owner())
		data["code_id"]=window.location.hash.substr(1);
	else {
		data["parent"]=window.location.hash.substr(1);
	}

	$.post(loc,
		JSON.stringify(data),
		function(result) {
			window.location.replace('/e#'+result);
			load_url_code();
		}, "text");
}

function load_code(hash) {
	if (gl) {
		compileButton.title = '';
		compileButton.style.color = '#ffff00';
		compileButton.textContent = 'Loading...';
	}
	set_save_button('hidden');
	set_parent_button('hidden');

	$.getJSON('/item/'+hash, function(result) {
		compileOnChangeCode = false;  // Prevent compile timer start
		code.setValue(result['code']);
		original_code=code.getValue();

		if(result['parent']) {
			original_version=result['parent'];
			parentButton.href = original_version;
			diffButton.href = 'diff#' + original_version.substring(3) + '-vs-' + hash;
			set_parent_button('visible');
		} else {
			original_version='';
			parentButton.href = '/';
			diffButton.href = '/';
			set_parent_button('hidden');
		}

		effect_owner=result['user'];

		if(am_i_owner())
			saveButton.textContent = 'save';
		else
			saveButton.textContent = 'fork';

		resetSurface();
		compile();
		compileOnChangeCode = true;
	});
}

// dummy functions

function setURL(fragment) {
}

function set_cookie(cookie, value, exp) {
	var cookieExpDate = new Date();
	var days = 1;
	if(typeof exp != "undefined" && exp != null) {
		days = Math.max(days, exp);
	}
	cookieExpDate.setDate(cookieExpDate.getDate() + days);
	document.cookie = cookie + "=" + value.toString() + "; expires=" + cookieExpDate.toUTCString();
}

function get_cookie(cookie, type) {
	var start = document.cookie.indexOf(cookie);
	if(start == -1) {
		return null;
	}
	var value = null;
	var end = document.cookie.indexOf(";", start);
	if(end == -1) {
		value = document.cookie.substring(start).split("=")[1];
	}
	else {
		var sub = document.cookie.substring(start, end);
		value = sub.split("=")[1];
	}
	switch(type) {
		case "string":
			value = value;
			break;
		case "integer":
			value = parseInt(value);
			break;
		case "float":
			value = parseFloat(value);
			break;

	}
	return value;
}