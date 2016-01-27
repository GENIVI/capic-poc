/* SPDX license identifier: EPL-1.0
 * Copyright (C) 2015, Visteon Corp.
 *
 * This file is part of Common API C
 *
 * This program and the accompanying materials are made available
 * under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html.
 * For further information see http://www.genivi.org/.
 *
 * Contributors:
 *   Pavel Konopelko, pkonopel@visteon.com
 */
package org.genivi.capic.core.ui.handlers;

import java.io.InputStream;

import org.eclipse.core.resources.IFile;
import org.eclipse.core.resources.IFolder;
import org.eclipse.core.resources.IProject;
import org.eclipse.core.resources.IResource;
import org.eclipse.core.runtime.CoreException;
import org.eclipse.core.runtime.Path;
import org.genivi.capic.core.IFileMaker;

public class WorkspaceFileMaker implements IFileMaker {
    private IProject parent;

    public WorkspaceFileMaker(IProject parent) {
        this.parent = parent;
    }

    public IFile makeFile(String pathName, String fileName, InputStream source) {
        //FIXME: recursively create nested folders under OUT_FOLDER
        //String targetFolderName = OUT_FOLDER + Path.SEPARATOR + pathName;
        String targetFolderName = SRCGEN_FOLDER;
        try {
            if (!parent.isOpen())
                parent.open(null);
            Path folderPath = new Path(targetFolderName);
            IFolder folder = parent.getFolder(folderPath);
            if (!folder.exists())
                folder.create(IResource.FORCE | IResource.DERIVED, false, null);
            IFile file = folder.getFile(fileName);
            if (file.exists())
                file.delete(IResource.FORCE, null);
            file.create(source, IResource.FORCE, null);
            return file;

        } catch (CoreException e) {
            //FIXME: re-throw
            System.out.println("Unable to crate output folder or file: " + e.getMessage());
            return null;
        }
    }
}
