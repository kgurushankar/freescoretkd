<?php include( "../../include/php/config.php" ); ?>
<html>
	<head>
		<link href="../../include/css/flippable.css" rel="stylesheet" />
		<link href="../../include/css/forms/grassroots/tiebreaker.css" rel="stylesheet" />
		<link href="../../include/css/forms/grassroots/grassrootsApp.css" rel="stylesheet" />
		<link href="../../include/fontawesome/css/font-awesome.min.css" rel="stylesheet" />
		<link href="../../include/css/brackets.css" rel="stylesheet" />
		<script src="../../include/jquery/js/jquery.js"></script>
		<script src="../../include/jquery/js/jquery-ui.min.js"></script>
		<script src="../../include/jquery/js/jquery.purl.js"></script>
		<script src="../../include/jquery/js/jquery.cookie.js"></script>
		<script src="../../include/js/freescore.js"></script>
		<script src="../../include/js/forms/grassroots/score.class.js"></script>
		<script src="../../include/js/forms/grassroots/athlete.class.js"></script>
		<script src="../../include/js/forms/grassroots/division.class.js"></script>
		<script src="../../include/js/forms/grassroots/jquery.grassroots.js"></script>
		<script src="../../include/js/forms/grassroots/jquery.voteDisplay.js"></script>
		<script src="../../include/js/forms/grassroots/jquery.leaderboard.js"></script>
		<script src="../../include/js/forms/grassroots/jquery.scoreboard.js"></script>
		<script src="../../include/js/forms/grassroots/jquery.judgeScore.js"></script>
		<script src="../../include/opt/svg/svg.min.js"></script>
		<script src="../../include/bootstrap/add-ons/brackets.js"></script>
	</head>
	<body>
		<div id="grassroots"></div>
		<script type="text/javascript">
			$( '#grassroots' ).grassroots( { server : '<?= $host ?>', tournament : <?= $tournament ?> });
		</script>
	</body>
</html>
