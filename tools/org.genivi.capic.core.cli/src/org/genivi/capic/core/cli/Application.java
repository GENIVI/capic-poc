/* SPDX license identifier: MPL-2.0
 * Copyright (C) 2015, Visteon Corp.
 * Author: Pavel Konopelko, pkonopel@visteon.com
 *
 * This file is part of Common API C
 *
 * This Source Code Form is subject to the terms of the
 * Mozilla Public License (MPL), version 2.0.
 * If a copy of the MPL was not distributed with this file,
 * you can obtain one at http://mozilla.org/MPL/2.0/.
 * For further information see http://www.genivi.org/.
 */
package org.genivi.capic.core.cli;

import org.apache.log4j.BasicConfigurator;
import org.apache.log4j.Level;
import org.apache.log4j.Logger;
import org.eclipse.core.resources.IFile;
import org.eclipse.core.resources.IProject;
import org.eclipse.core.resources.IResource;
import org.eclipse.core.resources.IWorkspace;
import org.eclipse.core.resources.IWorkspaceRoot;
import org.eclipse.core.resources.ResourcesPlugin;
import org.eclipse.core.runtime.CoreException;
import org.eclipse.core.runtime.IPath;
import org.eclipse.core.runtime.IStatus;
import org.eclipse.core.runtime.Path;
import org.eclipse.equinox.app.IApplication;
import org.eclipse.equinox.app.IApplicationContext;
import org.franca.core.dsl.FrancaIDLStandaloneSetup;
import org.genivi.capic.core.Generator;
import com.google.inject.Injector;

public class Application implements IApplication {
    private static String usageText = "Usage:\ncapic-core-gen <fidl-file>";
    private Injector injector;

    @Override
    public Object start(IApplicationContext context) throws Exception {
        injector = new FrancaIDLStandaloneSetup().createInjectorAndDoEMFRegistration();

        //FIXME: Make logging configurable
        BasicConfigurator.configure();
        Logger logger = Logger.getRootLogger();
        logger.setLevel(Level.WARN);

        System.out.println("GENIVI Common API C Core Standalone Generator");
        final String[] appArgs = (String[]) context.getArguments().get(
            IApplicationContext.APPLICATION_ARGS);
        for (final String arg : appArgs)
            System.out.println(arg);
        if (appArgs.length != 1) {
            System.out.println("Illegal number of arguments");
            System.out.println(usageText);
            return IApplication.EXIT_OK;
        }

        IWorkspace workspace = ResourcesPlugin.getWorkspace();
        IWorkspaceRoot root = workspace.getRoot();
        //System.out.println("WorkspaceRoot.Location = " + root.getLocationURI());

        IProject project = root.getProject("CAPIC Temporary");
        if (!project.exists())
            project.create(null);
        if (!project.isOpen())
            project.open(null);

        IPath location = new Path(appArgs[0]);
        IFile file = project.getFile(location.lastSegment());
        IStatus status = workspace.validateLinkLocation(file, location);
        if (!status.isOK()) {
            System.out.println("Invalid file location: " + status.getMessage());
            return IApplication.EXIT_OK;
        }

        try {
            file.createLink(location, IResource.REPLACE, null);
        } catch (CoreException e) {
            System.out.println("Unable to link input file: " + e.getMessage());
            return IApplication.EXIT_OK;
        }

        Generator generator = injector.getInstance(Generator.class);
        System.out.println(generator.generate(file, new LocalFileMaker(project)));

        try {
            project.close(null);
            project.delete(IResource.FORCE | IResource.ALWAYS_DELETE_PROJECT_CONTENT, null);
            workspace.save(true, null);
        } catch (CoreException e) {
            // silently ignore failure to clean up and save the workspace
        }

        return IApplication.EXIT_OK;
    }

    @Override
    public void stop() {
    }

}
