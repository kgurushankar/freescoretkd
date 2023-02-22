<?php
	include "../../../include/php/config.php";
?>
<html>
	<head>
	<title>New Division</title>
		<link href="../../../include/jquery/css/smoothness/jquery-ui.css" rel="stylesheet" />
		<link href="../../../include/bootstrap/css/bootstrap.min.css" rel="stylesheet" />
		<link href="../../../include/bootstrap/css/bootstrap-theme.min.css" rel="stylesheet" />
		<link href="../../../include/bootstrap/add-ons/bootstrap-select.min.css" rel="stylesheet" />
		<link href="../../../include/bootstrap/add-ons/bootstrap-switch.min.css" rel="stylesheet" />
		<link href="../../../include/opt/codemirror/lib/codemirror.css" rel="stylesheet" />
		<link href="../../../include/css/forms/worldclass/division/editor.css" rel="stylesheet" />
		<link href="../../../include/alertify/css/alertify.min.css" rel="stylesheet" />
		<link href="../../../include/alertify/css/themes/default.min.css" rel="stylesheet" />
		<script src="../../../include/jquery/js/jquery.js"></script>
		<script src="../../../include/jquery/js/jquery-ui.min.js"></script>
		<script src="../../../include/jquery/js/jquery.howler.min.js"></script>
		<script src="../../../include/jquery/js/jquery.cookie.js"></script>
		<script src="../../../include/bootstrap/js/bootstrap.min.js"></script>
		<script src="../../../include/bootstrap/add-ons/bootbox.min.js"></script>
		<script src="../../../include/bootstrap/add-ons/bootstrap-select.min.js"></script>
		<script src="../../../include/bootstrap/add-ons/bootstrap-switch.min.js"></script>
		<script src="../../../include/alertify/alertify.min.js"></script>
		<script src="../../../include/opt/codemirror/lib/codemirror.js"></script>
		<script src="../../../include/opt/codemirror/mode/freescore/freescore.js"></script>
		<script src="../../../include/js/freescore.js"></script>
		<script src="../../../include/js/forms/worldclass/score.class.js"></script>
		<script src="../../../include/js/forms/worldclass/athlete.class.js"></script>
		<script src="../../../include/js/forms/worldclass/division.class.js"></script>
		<meta name="viewport" content="width=device-width, initial-scale=1"></meta>
		<style>
		</style>
	</head>
	<body>
		<script>
			// ===== APPLICATION GLOBAL VARIABLES
			var sound    = {
				send      : new Howl({ urls: [ "../../../sounds/upload.mp3",   "../../../sounds/upload.ogg"   ]}),
				confirmed : new Howl({ urls: [ "../../../sounds/received.mp3", "../../../sounds/received.ogg" ]}),
				error     : new Howl({ urls: [ "../../../sounds/quack.mp3",    "../../../sounds/quack.ogg"    ]}),
				next      : new Howl({ urls: [ "../../../sounds/next.mp3",     "../../../sounds/next.ogg"   ]}),
				prev      : new Howl({ urls: [ "../../../sounds/prev.mp3",     "../../../sounds/prev.ogg"   ]}),
			};

			var division    = { athletes : [], flight: false, judges : 5, summary : function() { var summary = this.name.toUpperCase() + ' ' + this.description; if( this.flight ) { summary += ` [Flight ${JSON.parse(this.flight).id.toUpperCase()}]`; } return summary; }};
			var init        = {};
			var settings    = {};
			var description = {};
			var athletes    = {};
			var validate    = {};
			var warnings    = { not_enough_athletes: false, duplicate_athletes: false, not_enough_forms: false, clear: () => { Object.keys( warnings ).filter( i => i != 'clear' ).forEach( i => warnings[ i ] = false );}};
			var set         = ( key, value ) => { division[ key ] = value; }; // Workaround closure to edit top-level division
		</script>

		<div class="container">
			<div class="page-header"><h1>New Division</h1></div>

<?php include( "settings.php" ); ?>
<?php include( "description.php" ); ?>
<?php include( "forms.php" ); ?>

			<div class="panel panel-primary">
				<div class="panel-heading">
					<h4 class="panel-title">List of Athletes in this Division <span class="meta" style="float: right;">Please type LAST NAME in UPPERCASE</span></h4>
				</div>
				<textarea id="athletes" class="panel-body"></textarea>
				<div class="panel-footer">
					<button type="button" id="cancel-button" class="btn btn-warning pull-left"><span class="glyphicon glyphicon-remove-sign"></span> Cancel and Exit</button>
					<button type="button" id="save-button" class="btn btn-success pull-right"><span class="glyphicon glyphicon-save"></span> Save and Exit</button>
					<button type="button" id="randomize-button" class="btn btn-primary pull-right disabled" style="margin-right: 30px;"><span class="fas fa-random"></span> Randomize Order</button>
					<div class="clearfix"></div>
				</div>
			</div>
		</div>

		<script>
			// ===== ENSURE ONLY ONE HEADING EDITOR IS SHOWN (EXPANDED) AT A TIME
			$( ".collapse" ).on( "show.bs.collapse", ( ev ) => { $( ".collapse.in" ).collapse( 'hide' ); });

			// ============================================================
			// ATHLETE LIST (CODEMIRROR)
			// ============================================================
			athletes.textarea = $( '#athletes' );
			athletes.editor   = CodeMirror.fromTextArea( document.getElementById( 'athletes' ), { lineNumbers: true, autofocus: true, mode : 'freescore' });
			athletes.doc      = athletes.editor.getDoc();
			athletes.editor.setSize( '100%', '360px' );
			athletes.editor.on( "focus", ( ev ) => { $( ".collapse.in" ).collapse( 'hide' ); });

			// ===== BEHAVIOR
			athletes.editor.on( "change", function( cm, key, ev ) {
				division.athletes = ((athletes.doc.getValue().trim()).split( "\n" )).map( x => { return { name : x.trim() }});
				var n = division.athletes.length;

				var autodetect = $( 'label.active input[value=auto]' ).length > 0;
				if( autodetect ) { settings.round.select.autodetect(); }
				selected.update();

				validate.athletes.enable = true;
				validate.input();
			});

			init.athletes = ( division ) => {
				var list = division.athletes();
				var text = list.map( ( element ) => { return element.name(); }).join( "\n" );
				athletes.doc.setValue( text );
			};

			validate.athletes = { enable : false };

			validate.athletes.count = function() {
				if( division.athletes.length == 0 ) { return false; }
				randomize.enable();
				return (division.athletes[ 0 ].name);
			}
			validate.athletes.unique = function() {
				var duplicates = [];
				if( division.athletes.length > 1 ) {
					var count = division.athletes
						.map( (athlete) => { return athlete.name; })
						.reduce((uniq, cur) => { uniq[ cur ] = (uniq[ cur ] || 0) + 1; return uniq; }, {});
					duplicates = Object.keys( count ).filter((a) => count[a] > 1 );
				}
				return (duplicates.length == 0);
			}

			validate.input = function() {
				save.disable();
				var ok = true;

				if( validate.athletes.count() && validate.athletes.unique()) {
					$( '#athletes' ).parent().removeClass( "panel-danger" ).addClass( "panel-primary" );

				} else if( ! validate.athletes.count() ) {
					if( ! validate.athletes.enable ) { return; }
					ok = false;
					$( '#athletes' ).parent().removeClass( "panel-primary" ).addClass( "panel-danger" );
					if( ! warnings.not_enough_athletes ) {
						alertify.error( "Not enough athletes. Please add more athletes.", 10 );
						warnings.not_enough_athletes = true;
					}

				} else if( ! validate.athletes.unique() ) {
					ok = false;
					$( '#athletes' ).parent().removeClass( "panel-primary" ).addClass( "panel-danger" );
					if( ! warnings.duplicate_athletes ) {
						alertify.error( "Duplicate athletes. Please resolve athletes with the same name.", 10 );
						warnings.duplicate_athletes = true;
					}
				}

				if ( validate.selection() ) {
					$( '#form-selection' ).parent().removeClass( "panel-danger" ).addClass( "panel-primary" );
				} else {
					ok = false;
					$( '#form-selection' ).parent().addClass( "panel-danger" ).removeClass( "panel-primary" );
					if( ! warnings.not_enough_forms ) {
						alertify.error( "Not enough forms selected. Please select forms.", 10 );
						warnings.not_enough_forms = true;
					}
				}
				if( ok ) {
					warnings.clear();
					save.enable();
				}
				return ok;
			}

			// ===== SERVICE COMMUNICATION
			var file       = String( "<?= $_GET[ 'file' ] ?>" ).split( /\// ); file.shift(); // Tournament name
			var tournament = <?= $tournament ?>;
			var ring       = file.shift();
			var divId      = file.shift();
			var ws         = new WebSocket( `<?= $config->websocket( 'worldclass' ) ?>/${tournament.db}/${ring}/computer+operator` );
			var draws      = undefined;
			var save       = { enable : function() {
				var button = $( '#save-button' );
				button.off( 'click' ).click( function() { 

					// ===== COPY OVER ADDITIONAL VARIABLES
					division.ring = ring;
					if( $( '#flight' ).val()) { division.flight = JSON.parse( $( '#flight' ).val()); }

					var request  = { data : { type : 'division', action : 'write', division : division }};
					request.json = JSON.stringify( request.data );
					sound.next.play();
					ws.send( request.json );
				});
			}, disable : function() {
				var button = $( '#save-button' );
				button.off( 'click' ).click( function() {  // MW
					var english = { not_enough_athletes: 'Not enough athletes. Please add more athletes.', duplicate_athletes: 'Duplicate athletes. Each athlete name must be unique.', not_enough_forms: 'Not enough forms. Please assign more forms to this division.' };
					var faults  = '<ul>' + Object.keys( warnings ).filter( i => i != 'clear' && warnings[ i ] ).map( i => `<li>${english[ i ]}</li>` ).join( '' ) + '</ul>';

					alertify.confirm( 'This Division Does Not Conform to Rules', '<p>This division does not follow USAT or WT rules.</p>' + faults + '<p>Click <b>OK</b> to save, or <b>Cancel</b> to go back to editing without saving</p>', () => {
						// ===== COPY OVER ADDITIONAL VARIABLES
						division.ring = ring;
						if( $( '#flight' ).val()) { division.flight = JSON.parse( $( '#flight' ).val()); }

						var request  = { data : { type : 'division', action : 'write', division : division }};
						request.json = JSON.stringify( request.data );
						sound.next.play();
						ws.send( request.json );
					}, () => {});
				});
			}};

			$( '#cancel-button' ).off( 'click' ).click(() => { sound.prev.play(); setTimeout( () => { window.close(); }, 500 ); });
			var randomize  = { enable : function() {
				var button = $( '#randomize-button' );
				button.removeClass( 'disabled' );
				button.off( 'click' ).click( function() {
					var list = athletes.doc.getValue().split( '\n' );
					for( var i = list.length - 1; i >= 0; i-- ) {
						var j    = Math.floor( Math.random() * (i + 1));
						var swap = list[ i ];
						list[ i ] = list[ j ];
						list[ j ] = swap;
					}
					var text = list.join( '\n' );
					athletes.doc.setValue( text );
				});

			}, disable : function() {
				var button = $( '#randomize-button' );
				button.addClass( 'disabled' );
				button.off( 'click' );
			}};

			ws.onopen      = function() {
				// ===== LOAD POOMSAE DRAWS
				var request = { type : 'ring', action : 'read', ring : ring };
				var json    = JSON.stringify( request );
				ws.send( json );

				// ===== LOAD DIVISION
				if( divId != 'new' ) {
					request = { type : 'division', action : 'read', divid : divId };
					json    = JSON.stringify( request );
					ws.send( json );
				}
			};

			ws.onmessage = function( response ) {
				var update = JSON.parse( response.data );
				console.log( update );
				if( update.type == 'ring' ) {
					if( update.action = 'ring' ) {
						if( defined( update.ring ) && defined( update.ring.draws )) {
							draws = update.ring.draws;
							draws.select = ( description, division, forms ) => {
								var category = description.category.capitalize();
								var gender   = description.gender ? description.gender : 'c'; // Default to (c)oed
								var age      = description.years;
								var rank     = description.rank   ? description.rank   : 'k'; // Default to blac(k) belt
								var ready    = category && gender && age;
								var n        = division.athletes.length;
								var flight   = defined( division.flight ) || $( '#flight' ).val().length > 0;
								if( ! ready ) { return; }

								var d = draws[ category ];
								if( defined( d )) { d = d[ gender ]; if( ! defined( d )) { d = draws[ category ].c; }}
								if( defined( d )) { d = d[ age ]; }
								if( ! defined( d )) { return; }

								Object.keys( d ).forEach(( round ) => { if( ! selected.manual[ round ] ) { forms[ round ] = d[ round ].slice(); }});
								if( n <  20 && ! flight ) { delete forms.prelim; }
								if( n <= 8              ) { delete forms.semfin; }

								// Update Form Selection on Form Selector
								for( round in forms ) {
									for( var i = 0; i < forms[ round ].length; i++ ) {
										var form    = forms[ round ][ i ];
										var target  = $( `#${round}${i+1}` );
										var current = target.selectpicker( 'val' );
										if( form != current ) {
											target.selectpicker( 'val', form );
										}
									}
								}
							};
							$( '#form-selection' ).parent().removeClass( "panel-danger" ).addClass( "panel-primary" );
							alertify.message( 'Draws are available; complete the division <b>Description</b> to get the forms' );
						}
					}
				} else if( update.type == 'division' ) {
					if( update.action == 'update' ) {
						var division = new Division( update.division );

						if( division.is.flight()) { set( 'flight', JSON.stringify( division.flight())); }

						init.settings( division );
						init.description( division );
						init.forms( division );
						init.athletes( division );

					} else if( update.action == 'write ok' ) {
						var division = new Division( update.division );
						sound.send.play();
						bootbox.alert( "Division " + division.name().toUpperCase() + " saved.", () => { window.close(); } );

						init.athletes( division );

					} else if( update.action == 'write error' ) {
						var division = update.division;
						sound.next.play();
						bootbox.dialog({
							title : "Division " + division.name.toUpperCase() + " already exists!",
							message: "Do you want to overwrite the existing division " + division.name.toUpperCase() + "?",
							buttons: {
								cancel : {
									label: 'Cancel',
									className: 'btn-danger',
									callback: () => { sound.prev.play(); }
								},
								confirm : {
									label: 'Overwrite',
									className: 'btn-primary',
									callback: () => {
										sound.next.play();
										var request  = { data : { type : 'division', action : 'write', overwrite: true, division : division }};
										request.json = JSON.stringify( request.data );
										ws.send( request.json );
									}
								},
								rename : {
									label: 'Save As...',
									className: 'btn-success',
									callback: () => {
										sound.next.play();
										bootbox.prompt({
											title: 'Save Division As...',
											value: division.name.toUpperCase(),
											callback: ( name ) => {
												if( name === null ) { sound.prev.play(); return; }
												sound.next.play();
												division.name = name.toLowerCase();
												var request  = { data : { type : 'division', action : 'write', division : division }};
												request.json = JSON.stringify( request.data );
												ws.send( request.json );
											}
										});
									}
								},
							},
							closeButton : false,
						});
					}
				}
			};
			ws.onclose   = function( reason ) {
				bootbox.alert( { title: 'Network Error', message: 'An error occurred while attempting to connect to the server.', callback: function() { window.close(); }} );
			};
		</script>

	</body>
</html>
