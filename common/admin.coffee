@Users = db.users
@spaces = db.spaces
@space_users = db.space_users
@organizations = db.organizations


@AdminConfig = 
        name: "Steedos Admin"
        skin: "blue"
        userSchema: null,
        userSchema: db.users._simpleSchema,
        autoForm:
                omitFields: ['createdAt', 'updatedAt', 'created', 'created_by', 'modified', 'modified_by']
        collections: 

                spaces: db.spaces.adminCofig

                space_users: db.space_users.adminConfig

                organizations: db.organizations.adminConfig

        callbacks:
                onInsert: (name, insertDoc, updateDoc, currentDoc) ->
                        if Meteor.isClient
                                if name == "spaces"
                                        Meteor.call "setSpaceId", insertDoc._id, ->
                                                Session.set("spaceId", insertDoc._id)

                                                  

# set first user as admin
if Meteor.isServer
        adminUser = Meteor.users.findOne({},{sort:{createdAt:1}})
        if adminUser
                adminUserId = adminUser._id
                if !Roles.userIsInRole(adminUserId, ['admin'])
                        Roles.addUsersToRoles adminUserId, ['admin'], Roles.GLOBAL_GROUP