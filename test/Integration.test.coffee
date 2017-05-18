Promise = require('bluebird')
weaver = require("./test-suite")
Weaver = require('../src/Weaver')

alphaProject = null
betaProject  = null

describe 'Integration Test', ->

  it 'should demonstrate and assess all Weaver functionality', ->

    # Map to save state between promises
    reg = {}

    # Weaver is already connected by test-suite
    # This test assumes a fully initialized Weaver Server, meaning
    # - no users or projects
    # - no data in any database
    # We therefore call the wipe function that only works in Development mode
    weaver.wipe()
    .then(->

      # There is always an admin user that we can use to sign in
      # Default username and password are set in weaver-server config file
      weaver.signInWithUsername('admin', 'admin')

    ).then(->

      # Create a project with a name
      alphaProject = new Weaver.Project("Alpha Project")
      alphaProject.create()

    ).then(->

      # Use the created project for creating nodes
      weaver.useProject(alphaProject)

      # Create a node
      # By default, this will create an ACL that only allows currentUser (being admin) to read/write this node
      node = new Weaver.Node('adminPrivateNode')
      node.set('name', "Foo")
      node.set('isBar', false)
      node.set('age', 30)
      node.save()

    ).then((node) ->

      # Check that loading the node from the server works
      Weaver.Node.load('adminPrivateNode')

    ).then((node) ->

      # Signup with a different user and assess that that user has no right to read this project
      john = new Weaver.User('john', "secretSauce", "john@doe.com")
      reg.john = john # Save for later

      john.signUp()

    ).catch(->
      assert false # Up until this point no error should be thrown
    )
    .then(->
      # Now we should not be able to load the private node
      Weaver.Node.load('adminPrivateNode')
    ).then(->
      assert false
    ).catch((error) ->
      assert true
    ).then(->

      ###
      Give john read access to the project (later we give him write access) with these steps:
      1. Signin as admin user
      2. Create a new role
      3. Add John to this newly created role
      4. Add this role to the project ACL as read allowed
      ###

      weaver.signInWithUsername('admin', 'admin')

    ).then(->

      # Note that the ACL of the role itself is again set to the Admin user,
      # meaning only Admin can change this role by adding/removing users
      readRole = new Weaver.Role("Alpha Project Read role")
      readRole.addUser(reg.john)
      readRole.save()

      reg.readRole = readRole # Save for later

    ).then((readRole) ->

      # Load the ACL of currentProject
      weaver.currentProject().getACL()

    ).then((projectACL) ->

      reg.projectACL = projectACL # Save for later

      # Add the new role to be able to read
      projectACL.setRoleReadAccess(reg.readRole, true) #TODO: Rename to add and remove
      projectACL.save()

    ).then(->

      # Now sign in as John to test project read access
      weaver.signInWithUsername('john', 'secretSauce')

    ).then(->

      # Should now be able to read this node
      Weaver.Node.load('adminPrivateNode')

    ).then((node) ->

      assert.equal(node.get('name'), 'Foo')

      # Assert that writing is still not allowed
      node.set('name', 'Sonic')
      node.save()

    ).then(->
      assert false
    ).catch((error) ->
      assert true
    ).then(->

      # Give john write access to the project by creating a write role and adding john to it
      # First sign in as admin
      weaver.signInWithUsername('admin', 'admin')

    ).then(->

      # Add the new write role
      writeRole = new Weaver.Role("Alpha Project Write role")
      writeRole.addUser(reg.john)
      writeRole.save()

    ).then((writeRole) ->

      # Add this role to the write access of the project
      reg.projectACL.setRoleWriteAccess(writeRole, true)
      reg.projectACL.save()

    ).then(->

      # Load again
      Weaver.Node.load('adminPrivateNode')

    ).then((node)->

      # Change the name
      node.set('name', 'Sonic')
      node.save()

    ).then((node) ->

      assert.equal(node.get('name'), 'Sonic')
    )
    .catch((error) ->
      assert false
    )
