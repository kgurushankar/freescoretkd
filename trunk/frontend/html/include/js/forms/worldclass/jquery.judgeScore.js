$.widget( "freescore.judgeScore", {
	options: { autoShow: true, num: 0, max: 3, complete : false },
	_create: function() {
		var o       = this.options;
		var e       = this.options.elements = {};
		var html    = e.html  = FreeScore.html;
		var score   = e.score = html.div.clone() .addClass( "score" ) .prop( "id", "judgeScore" + o.num );
		var name    = e.name  = html.div.clone() .addClass( "judge" );
		var view    = e.view  = html.div.clone();
		score.append( view );
		name .html( o.num == 1 ? 'R' : o.num - 1 );
		this.element .addClass( "judgeScore" );
		this.element .append( name, score );
	},
	_init: function( ) {
		var e        = this.options.elements;
		var o        = this.options;
		var w        = this.element;
		var score    = o.score;
		var ok       = '&#10004;';

		w.css( "top", (o.num - 1) * 103 );
		if     ( o.num == 1 ) { w.css( "border-radius", "24px 0 0 0" ); e.name.css( "border-radius", "24px 0 0 0" );}
		else if( o.num == 7 ) { w.css( "border-radius", "0 0 0 24px" ); e.name.css( "border-radius", "0 0 0 24px" );}

		if( o.num > o.max ) { e.name.addClass( "ignore-judge" ); } else { e.name.removeClass( "ignore-judge" ); }
		
		if( defined( score )) {
			if( o.complete ) {
				score.accuracy     = defined( score.accuracy )     ?  score.accuracy.toFixed( 1 )     : '';
				score.presentation = defined( score.presentation ) ?  score.presentation.toFixed( 1 ) : '';

			} else {
				score.accuracy     = defined( score.accuracy )     ?  ok : '';
				score.presentation = defined( score.presentation ) ?  ok : '';
			}
		} else {
			score = { accuracy : '', presentation : '' };
		}

		// ===== DISPLAY VALID SCORES
		if((score.accuracy == ok || parseFloat( score.accuracy ) >= 0) && (score.presentation == ok || parseFloat( score.presentation ) > 0)) { 
			var span = {
				accuracy     : e.html.span .clone() .addClass( "accuracy"     ) .html( score.accuracy     ),
				presentation : e.html.span .clone() .addClass( "presentation" ) .html( score.presentation )
			};
			var ignore = { 
				accuracy     : o.max >= 5 && (score.minacc || score.maxacc),
				presentation : o.max >= 5 && (score.minpre || score.maxpre)
			};
			if( ignore.accuracy     ) { span.accuracy     .addClass( "ignore-acc" ); } else { span.accuracy     .removeClass( "ignore-acc" ); }
			if( ignore.presentation ) { span.presentation .addClass( "ignore-pre" ); } else { span.presentation .removeClass( "ignore-pre" ); }
			e.view.empty();
			e.view.append( span.accuracy, "&nbsp;", span.presentation );
			e.view.fadeIn(); 

		// ===== HIDE INVALID SCORES
		} else {
			e.view.empty();
			e.view.fadeOut();
		}
	}
});
