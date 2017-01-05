Template.instance_button.helpers

	show_suggestion: ->
		isShow = !ApproveManager.isReadOnly() || InstanceManager.isInbox();
		if isShow
			isShow = WorkflowManager.getInstance().state != "draft"
		return isShow
	enabled_save: ->
		ins = WorkflowManager.getInstance();
		if !ins
			return "display: none;";
		flow = db.flows.findOne(ins.flow);
		if !flow
			return "display: none;";

		if InstanceManager.isInbox()
			return "";

		if !ApproveManager.isReadOnly()
			return "";
		else
			return "display: none;";

	enabled_delete: ->
		ins = WorkflowManager.getInstance();
		if !ins
			return "display: none;";
		space = db.spaces.findOne(ins.space);
		if !space
			return "display: none;";
		fl = db.flows.findOne({'_id': ins.flow});
		if !fl
			return "display: none;";
		curSpaceUser = db.space_users.findOne({space: ins.space, 'user': Meteor.userId()});
		if !curSpaceUser
			return "display: none;";
		organizations = db.organizations.find({_id: {$in: curSpaceUser.organizations}}).fetch();
		if !organizations
			return "display: none;";

		if Session.get("box") == "draft" || (Session.get("box") == "monitor" && space.admins.contains(Meteor.userId())) || (Session.get("box") == "monitor" && WorkflowManager.canAdmin(fl, curSpaceUser, organizations))
			return "";
		else
			return "display: none;";

	enabled_print: ->
#		如果是手机版APP，则不显示打印按钮
		if Meteor.isCordova
			return "display:none";
		return "";


	enabled_add_attachment: ->
		if !ApproveManager.isReadOnly()
			return "";
		else
			return "display: none;";

	enabled_terminate: ->
		ins = WorkflowManager.getInstance();
		if !ins
			return "display: none;";
		if (Session.get("box") == "pending" || Session.get("box") == "inbox") && ins.state == "pending" && ins.applicant == Meteor.userId()
			return "";
		else
			return "display: none;";

	enabled_reassign: ->
		ins = WorkflowManager.getInstance();
		if !ins
			return "display: none;";
		space = db.spaces.findOne(ins.space);
		if !space
			return "display: none;";
		fl = db.flows.findOne({'_id': ins.flow});
		if !fl
			return "display: none;";
		curSpaceUser = db.space_users.findOne({space: ins.space, 'user': Meteor.userId()});
		if !curSpaceUser
			return "display: none;";
		organizations = db.organizations.find({_id: {$in: curSpaceUser.organizations}}).fetch();
		if !organizations
			return "display: none;";

		if Session.get("box") == "monitor" && ins.state == "pending" && (space.admins.contains(Meteor.userId()) || WorkflowManager.canAdmin(fl, curSpaceUser, organizations))
			return "";
		else
			return "display: none;";

	enabled_relocate: ->
		ins = WorkflowManager.getInstance();
		if !ins
			return "display: none;";
		space = db.spaces.findOne(ins.space);
		if !space
			return "display: none;";
		fl = db.flows.findOne({'_id': ins.flow});
		if !fl
			return "display: none;";
		curSpaceUser = db.space_users.findOne({space: ins.space, 'user': Meteor.userId()});
		if !curSpaceUser
			return "display: none;";
		organizations = db.organizations.find({_id: {$in: curSpaceUser.organizations}}).fetch();
		if !organizations
			return "display: none;";

		if Session.get("box") == "monitor" && ins.state == "pending" && (space.admins.contains(Meteor.userId()) || WorkflowManager.canAdmin(fl, curSpaceUser, organizations))
			return "";
		else
			return "display: none;";

	enabled_cc: ->
		if InstanceManager.isInbox()
			return "";
		else
			return "display: none;";

	enabled_forward: ->
		is_paid = WorkflowManager.isPaidSpace(Session.get('spaceId'));
		if is_paid
			ins = WorkflowManager.getInstance()
			if !ins
				return "display: none;"

			if ins.state != "draft" && !Steedos.isMobile()
				return ""
			else
				return "display: none;"
		else
			return "display: none;"

	enabled_retrieve: ->
		ins = WorkflowManager.getInstance()
		if !ins
			return "display: none;"

		if (Session.get('box') is 'outbox' or Session.get('box') is 'pending') and ins.state is 'pending'
			last_trace = _.find(ins.traces, (t)->
				return t.is_finished is false
			)
			previous_trace_id = last_trace.previous_trace_ids[0];
			previous_trace = _.find(ins.traces, (t)->
				return t._id is previous_trace_id
			)
			# 校验取回步骤的前一个步骤approve唯一并且处理人是当前用户
			previous_trace_approves = previous_trace.approves
			if previous_trace_approves.length is 1 and previous_trace_approves[0].user is Meteor.userId()
				return ""
		return "display: none;"


Template.instance_button.events

	'click #instance_to_print': (event)->
		uobj = {}
		uobj["box"] = Session.get("box")
		uobj["X-User-Id"] = Meteor.userId()
		uobj["X-Auth-Token"] = Accounts._storedLoginToken()
		Steedos.openWindow(Meteor.absoluteUrl("workflow/space/" + Session.get("spaceId") + "/print/" + Session.get("instanceId") + "?" + $.param(uobj)))

	'click #instance_update': (event)->
		InstanceManager.saveIns();
		Session.set("instance_change", false);

	'click #instance_remove': (event)->
		swal {
			title: t("Are you sure?"),
			type: "warning",
			showCancelButton: true,
			cancelButtonText: t('Cancel'),
			confirmButtonColor: "#DD6B55",
			confirmButtonText: t('OK'),
			closeOnConfirm: true
		}, () ->
			Session.set("instance_change", false);
			InstanceManager.deleteIns()

	'click #instance_force_end': (event)->
		swal {
			title: t("instance_cancel_title"),
			text: t("instance_cancel_reason"),
			type: "input",
			confirmButtonText: t('OK'),
			cancelButtonText: t('Cancel'),
			showCancelButton: true,
			closeOnConfirm: false
		}, (reason) ->
			# 用户选择取消
			if (reason == false)
				return false;

			if (reason == "")
				swal.showInputError(t("instance_cancel_error_reason_required"));
				return false;

			InstanceManager.terminateIns(reason);
			sweetAlert.close();

	'click #instance_reassign': (event, template) ->
		Modal.show('reassign_modal')

	'click #instance_relocate': (event, template) ->
		Modal.show('relocate_modal')


	'click #instance_cc': (event, template) ->
		Modal.show('instance_cc_modal');

	'click #instance_forward': (event, template) ->
		#判断是否为欠费工作区
		if WorkflowManager.isArrearageSpace()
			toastr.error(t("spaces_isarrearageSpace"));
			return;

		Modal.show("forward_select_flow_modal")

	'click #instance_retrieve': (event, template) ->
		swal {
			title: t("instance_retrieve"),
			text: t("instance_retrieve_reason"),
			type: "input",
			confirmButtonText: t('OK'),
			cancelButtonText: t('Cancel'),
			showCancelButton: true,
			closeOnConfirm: false
		}, (reason) ->
			# 用户选择取消
			if (reason == false)
				return false;

			if (reason == "")
				swal.showInputError(t("instance_retrieve_reason"));
				return false;

			InstanceManager.retrieveIns(reason);
			sweetAlert.close();
