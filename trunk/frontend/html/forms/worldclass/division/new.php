<?php
	include "../../../include/php/config.php"
?>
<html>
	<head>
		<title>Create a New Division</title>
		<link href="../../../include/jquery/css/smoothness/jquery-ui.css" rel="stylesheet" />
		<link href="../../../include/bootstrap/css/bootstrap.min.css" rel="stylesheet" />
		<link href="../../../include/bootstrap/css/bootstrap-theme.min.css" rel="stylesheet" />
		<link href="../../../include/bootstrap/add-ons/bootstrap-select.min.css" rel="stylesheet" />
		<link href="../../../include/bootstrap/add-ons/bootstrap-switch.min.css" rel="stylesheet" />
		<link href="../../../include/opt/codemirror/lib/codemirror.css" rel="stylesheet" />
		<link href="../../../include/css/forms/worldclass/division/new.css" rel="stylesheet" />
		<script src="../../../include/jquery/js/jquery.js"></script>
		<script src="../../../include/jquery/js/jquery-ui.min.js"></script>
		<script src="../../../include/bootstrap/js/bootstrap.min.js"></script>
		<script src="../../../include/bootstrap/add-ons/bootbox.min.js"></script>
		<script src="../../../include/bootstrap/add-ons/bootstrap-select.min.js"></script>
		<script src="../../../include/bootstrap/add-ons/bootstrap-switch.min.js"></script>
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
		<div class="container">
			<div class="page-header">
				<h1>Create a New Division</h1>
			</div>

<?php include( "settings.php" ); ?>
<?php include( "description.php" ); ?>
<?php include( "form-selection.php" ); ?>

			<div class="panel panel-primary">
				<div class="panel-heading">
					<div class="btn-group pull-left">
						<span class="glyphicon glyphicon-menu-hamburger"></span>
					</div>
					<h4 class="panel-title">List of Athletes in this Division</h4>
				</div>
				<textarea id="athletes" class="panel-body"></textarea>
				<div class="panel-footer">
					<button type="button" id="save-button" class="btn btn-success pull-right "><span class="glyphicon glyphicon-save"></span> Save and Exit</button>
					<div class="clearfix"></div>
				</div>
			</div>
		</div>

		<script>
			var athletes = { textarea : $( '#athletes' ), editor : undefined };
			athletes.editor = CodeMirror.fromTextArea( document.getElementById( 'athletes' ), { lineNumbers: true, autofocus: true, mode : 'freescore' });
			athletes.editor.setSize( '100%', '360px' );

			$( '#save-button' ).removeClass( 'disabled' ) .click( function() { 
				bootbox.prompt({
					title: "Save Division " + (defined( division.description ) ? "&quot;" + division.description + "&quot;" : '' ) + " As?",
					value: (defined( division.name ) ? division.name : "p000"),
					callback: function( result ) {
						if( result === null ) { window.close(); } 
						else {
						}
					}
				});
			});

			// ===== SERVICE COMMUNICATION
			if( ! "WebSocket" in window ) { alert( "Browser does not support communication with the server via websockets." ); }
			/*
			var ws = new WebSocket( "ws://<?= $host ?>:3088/worldclass" );
			ws.onopen    = function() {
				var file       = String( "<?= $_GET[ 'file' ] ?>" ).split( /\// );
				var tournament = file.shift();
				var ring       = file.shift();
				$( '#save-button' ).removeClass( 'disabled' ) .click( function() { 
					var request  = { data : { type : 'division', action : 'write', division : division }};
					request.json = JSON.stringify( request.data );
					ws.send( request.json );
					window.close(); 
				});
			};
			ws.onmessage = function( ev ) {
			};
			ws.onclose   = function() {
			};
			 */
		</script>

	</body>
</html>
