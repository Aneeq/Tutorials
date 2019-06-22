(function ($) {

    $.telligent.evolution.ui.components.vote = {
        setup: function () {

        },
        add: function (elm, options) {
            var settings = $.extend({}, {
                isReadOnly: (options.readonly === 'true'),
                yesVotes: parseInt(options.initialyesvotes),
                noVotes: parseInt(options.initialnovotes),
                voteCount: parseInt(options.initialvotes),
                score: parseInt(options.initialscore),
                userVote: options.initialuservote,
                canUserUpVote: (options.canuserupvote === 'true'),
                canUserDownVote: (options.canuserdownvote === 'true'),
                isUserRegistered: (options.isuserregistered === 'true'),
                isUserGroupMember: (options.isusergroupmember === 'true'),
                loginUrl: options.loginurl
            });

            settings.onVote = function (value) {
                if (!options.contentid) {
                    return;
                }

                $.telligent.evolution.post({
                    url: $.telligent.evolution.site.getBaseUrl() + 'api.ashx/v2/ideas/vote.json',
                    data: {
                        IdeaId: options.contentid
                        ,Value: value
                    },
                    success: function (response) {

                        if (response && response.Vote && response.Vote.Idea) {
                            $(elm).evolutionUpDownVoting('option', {
                                yesVotes: response.Vote.Idea.YesVotes,
                                noVotes: response.Vote.Idea.NoVotes,
                                voteCount: response.Vote.Idea.TotalVotes,
                                score: response.Vote.Idea.Score,
                                userVote: response.Vote.Value
                            });
                        } else {
                            $(elm).evolutionUpDownVoting('option', {
                                yesVotes: 0,
                                noVotes: 0,
                                voteCount: 0,
                                score: 0,
                                userVote: null
                            });
                        }
                    }
                });
            };

            settings.onDeleteVote = function () {
                if (!options.contentid) {
                    return;
                }

                $.telligent.evolution.del({
                    url: $.telligent.evolution.site.getBaseUrl() + 'api.ashx/v2/ideas/vote.json',
                    data: {
                        IdeaId: options.contentid
                    },
                    success: function (response) {

                        $.telligent.evolution.get({
                            url: $.telligent.evolution.site.getBaseUrl() + 'api.ashx/v2/ideas/idea.json',
                            data: {
                                Id: options.contentid
                            },
                            success: function (response) {
                                if (response && response.Idea) {
                                    $(elm).evolutionUpDownVoting('option', {
                                        yesVotes: response.Idea.YesVotes,
                                        noVotes: response.Idea.NoVotes,
                                        voteCount: response.Idea.TotalVotes,
                                        score: response.Idea.Score,
                                        userVote: null
                                    });
                                } else {
                                    $(elm).evolutionUpDownVoting('option', {
                                        yesVotes: 0,
                                        noVotes: 0,
                                        voteCount: 0,
                                        score: 0,
                                        userVote: null
                                    });
                                }
                            }
                        });
                    }
                });
            };

            if (settings.voteCount == 0 && settings.isReadOnly) {
                return;
            }

            $(elm).evolutionUpDownVoting(settings);
        }
    };

} (jQuery));

(function ($, undefined) {

    var EVENT_NAMESPACE = '.evolutionUpDownVoting',
		CONTEXT_KEY = 'evolutionUpDownVoting_context',
		_getValue = function (context) {
		    if (typeof context.internal.yesVotes !== 'undefined') {
		        return context.internal.yesVotes;
		    } else {
		        return context.settings.yesVotes;
		    }
		},
		_setValue = function (context, value) {
		    if (!context.internal.isInitialized || context.settings.isReadOnly) {
		        return;
		    }

		    context.internal.userVote = value;

		    if (!context.settings.allowMultipleSelections) {
		        context.settings.isReadOnly = true;
		    }

		    context.internal.savingValue = true;

		    if (value == null)
		        context.settings.onDeleteVote();
		    else
		        context.settings.onVote(value);
		},
		_init = function (options) {
		    return this.each(function () {
		        var context = {
		            settings: $.extend({}, $.fn.evolutionUpDownVoting.defaults, options || {}),
		            internal: {
		                state: $(this)
		            }
		        };

		        $(this).data(CONTEXT_KEY, context);

		        _initialize(context);
		    });
		},
		_initialize = function (context) {
		    // first reset
		    context.internal.state
				.addClass(context.settings.voteClass)
				.css('white-space', 'nowrap')
				.find('a').unbind(EVENT_NAMESPACE)
				.empty()
				.end();

		    context.internal.state.empty();

		    if (context.settings.userVote == 'true') {
		        context.settings.userVote = true;
		    }
		    else if (context.settings.userVote == 'false') {
		        context.settings.userVote = false;
		    }

		    if (context.settings.isReadOnly) {
		        context.internal.state.addClass(context.settings.readOnlyClass);
		    }

		    _addVoteImage(context, true);
		    _addVoteSummary(context);
		    _addVoteImage(context, false);

		},
		_addVoteImage = function (context, value) {

		    var showLabels = typeof context.settings.voteCount === 'undefined';

		    (function () {

                //if a user is registered and is a member of the group, but does not have down vote permission, hide the down arrow
                if (context.settings.isUserRegistered && context.settings.isUserGroupMember && (value == false && !context.settings.canUserDownVote)) 
                    return;

                //only hide the up vote if the down vote will be visible.
                if (context.settings.isUserRegistered && context.settings.isUserGroupMember && (value == true && !context.settings.canUserUpVote && context.settings.canUserDownVote)) 
                    return;

		        var a;
		        var title = '';

	            title = _getImageText(context, value);

                //unregistered users get active arrows to login, users who can up vote or down vote with get the corresponding active arrow
		        if (!context.settings.isUserRegistered || (value == true && context.settings.canUserUpVote) || (value == false && context.settings.canUserDownVote)) {
		            a = $('<a href="#" >' + title + '</a>')
						.css({ textDecoration: 'none' })
						.attr('title', title)
                        .addClass('votingenabled');
		        }
                //all others will get a disabled arrow
		        else {
		            a = $('<a disabled="disabled">' + title + '</a>')
						.addClass(context.settings.readOnlyClass)
                        .attr('title', title)
                        .addClass('votingdisabled');
		        }

		        a.addClass('vote');
		        if (value == 1)
		            a.addClass('upvote');
		        else
		            a.addClass('downvote');


		        if (!context.settings.isReadOnly) {
		            if (!context.settings.isUserRegistered) {
		                a.attr('href', context.settings.loginUrl);
		            }
		            else if ((value == true && context.settings.canUserUpVote) || (value == false && context.settings.canUserDownVote)) {
		                if (context.settings.userVote == null || context.settings.userVote != value) {
		                    //vote
		                    a.data('rating-value', value)
    				            .bind('click' + EVENT_NAMESPACE, function (e) {
    				                _setValue(context, a.data('rating-value'));
    				                return false;
    				            })
		                }
		                else if (context.settings.userVote == value) {
		                    //delete
		                    a.data('rating-value', value)
								.addClass('selected')
			                    .bind('click' + EVENT_NAMESPACE, function (e) {
			                        _setValue(context, null);
			                        return false;
			                    });
		                }
		            }
		        }

		        context.internal.state.append(a);
		    })();

		    context.internal.isInitialized = true;
		},
		_addVoteSummary = function (context) {
		    var cssClass = 'neutral'
		    if (context.settings.score > 0) {
		        cssClass = 'positive'
		    } else if (context.settings.score < 0) {
		        cssClass = 'negative';
		    }

		    context.internal.state.append('<div class="score-summary"><div class="vote-score ' + cssClass + '">' + context.settings.score + '</div></div>');
		},
		_getImageText = function (context, value) {
            if (context.settings.isReadOnly) {
                return context.settings.readOnlyMessage;
            }
            //unregistered users who don't have the corresponding permission get a click to login message
		    if (((value == true && !context.settings.canUserUpVote) || (value == false && !context.settings.canUserDownVote)) && !context.settings.isUserRegistered) {
		        return context.settings.loginMessage;
		    }
		    else {
		        var imageText = '';
		        if ((value == true && !context.settings.canUserUpVote) || (value == false && !context.settings.canUserDownVote)) {
		            if (context.settings.isUserGroupMember) {
		                return context.settings.noPermissionMessage;
		            }
		            else {
		                return context.settings.notGroupMemberMessage;
		            }
		        }
		        else if ((context.settings.userVote == true && value == true) || (context.settings.userVote == false && value == false))
		            return context.settings.deleteMessage;
		        else if (value == true && context.settings.userVote == null)
                    return context.settings.voteUpMessage;
		        else if (value == true && context.settings.userVote == false)
		            return context.settings.switchToUpVoteMessage;
		        else if (value == false && context.settings.userVote == null)
		            return context.settings.voteDownMessage;
		        else if (value == false && context.settings.userVote == true)
		            return context.settings.switchToDownVoteMessage;
		    }

	        return '';
		};

    var api = {
        val: function (value) {
            var context = this.data(CONTEXT_KEY);
            if (context !== null) {
                if (typeof value !== 'undefined') {
                    context.internal.yesVotes = value;
                    //_showValue(context, value);
                    return value;
                } else {
                    return _getValue(context);
                }
            }
            return 0;
        },
        readOnly: function (readOnly) {
            var context = this.data(CONTEXT_KEY);
            if (context !== null) {
                if (typeof readOnly !== 'undefined') {
                    context.settings.isReadOnly = readOnly;
                    if (readOnly) {
                        context.internal.state.find('a').css({ cursor: 'default' });
                    } else {
                        context.internal.state.find('a').css({ cursor: 'pointer' });
                    }
                } else {
                    return context.settings.isReadOnly;
                }
            }
            return true;
        },
        option: function (name, value) {
            if (typeof name === 'object') {
                return this.each(function () {
                    var context = $(this).data(CONTEXT_KEY);
                    if (context != null) {
                        context.settings = $.extend({}, context.settings, name);
                        _init.apply($(this), [context.settings]);
                    }
                });
            } else if (typeof name !== 'undefined' && typeof value !== 'undefined') {
                return this.each(function () {
                    var context = $(this).data(CONTEXT_KEY);
                    if (context != null) {
                        context.settings[name] = value;
                        _init.apply($(this), [context.settings]);
                    }
                });
            }
            else if (typeof name !== 'undefined') {
                var context = this.data(CONTEXT_KEY);
                if (context !== null) {
                    return context.settings[name];
                } else {
                    return null;
                }
            }
        }
    };

    $.fn.evolutionUpDownVoting = function (method) {
        if (method in api) {
            return api[method].apply(this, Array.prototype.slice.call(arguments, 1));
        } else if (typeof method === 'object' || !method) {
            return _init.apply(this, arguments);
        } else {
            $.error('Method ' + method + ' does not exist on jQuery.fn.evolutionUpDownVoting');
        }
    };

    $.extend($.fn.evolutionUpDownVoting, {
        defaults: {
            yesVotes: 0,
            noVotes: 0,
            voteCount: 0,
            score: 0,
            userVote: null,
            voteClass: 'updownvote',
            overClass: 'active',
            readOnlyClass: 'readonly',
            isReadOnly: false,
            allowMultipleSelections: true,
            canUserUpVote: false,
            canUserDownVote: false,
            isUserRegistered: true,
            loginUrl: '',
            isUserGroupMember: false,
            voteDownMessage: 'Vote against this idea',
            voteUpMessage: 'Vote for this idea',
            loginMessage: 'Sign in to vote on ideas',
            noPermissionMessage: 'You do not have permission to vote for this idea',
            notGroupMemberMessage: 'Join this group to vote on this idea',
            deleteMessage: 'Remove your vote for this idea',
            readOnlyMessage: 'Voting has been disabled',
            switchToDownVoteMessage: 'Vote against this idea instead of for it',
            switchToUpVoteMessage: 'Vote for this idea instead of against it',
            onVote: function (value) { },
            onDeleteVote: function (value) { }
        }
    });

})(jQuery, undefined);