<?php 
	include_once( "../../include/php/config.php" ); 
	$referer = array_key_exists( 'referer', $_GET ) ? $_GET[ 'referer' ] : null;
?>
<html>
	<head>
		<link href="../../include/css/setup/register.css" rel="stylesheet" />
		<link href="../../include/bootstrap/css/bootstrap.min.css" rel="stylesheet" />
		<link href="../../include/bootstrap/css/bootstrap-theme.min.css" rel="stylesheet" />
		<script src="../../include/jquery/js/jquery.js"></script>
		<script src="../../include/jquery/js/jquery-ui.min.js"></script>
		<script src="../../include/jquery/js/jquery.cookie.js"></script>
		<script src="../../include/jquery/js/jquery.purl.js"></script>
		<script src="../../include/bootstrap/js/bootstrap.min.js"></script>
		<script src="../../include/bootstrap/add-ons/bootbox.min.js"></script>
		<script src="../../include/js/freescore.js"></script>
		<script src="../../include/js/forms/grassroots/jquery.register.js"></script>
	</head>
	<body>
		<div id="setup"></div>
		<script type="text/javascript">
			$( '#setup' ).register({ server : '<?= $config->webservice( 'grassroots' ) ?>', tournament : <?= $tournament ?>, 'event' : 'grassroots' });
		</script>
	</body>
</html>
