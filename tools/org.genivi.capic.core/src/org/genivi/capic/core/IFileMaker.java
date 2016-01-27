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
package org.genivi.capic.core;

import java.io.InputStream;

import org.eclipse.core.resources.IFile;

/**
 * File maker is a helper for creating folder and files.
 * <p>
 * Depending on from what context the code generator is being invoked, file
 * maker can be implemented to put the generated folders and files in a certain
 * place.  The latter can be, for example, the workspace or the local file
 * system.  The corresponding policy is set by the implementing class.
 * </p>
 */
public interface IFileMaker {
    /**
     * The default name of the leaf folder, where all generated folders and
     * files will be located.
     */
    public static final String SRCGEN_FOLDER = "src-gen";

    /**
     * Creates in the given path a file with the specified name and contents.
     * <p>
     * First, creates nested folders as specified by <code>pathName</code>.
     * The exact place in the workspace or in the local file system, where
     * the root folder is created, is determined by the class that implements
     * this interface.  The contents of already existing folders along the
     * requested <code>pathName</code> is kept unmodified.  The value of
     * <code>pathName</code> can be an empty string, in which case the file is
     * created in the implementation-specific default root folder.
     * </p>
     * <p>
     * Second, creates the file with the given <code>fileName</code> and
     * populates its contents from the <code>source</code>.  The file is
     * created in the leaf folder specified by the <code>pathName</code>.
     * However, the exact place in the workspace or in the local file system,
     * where the file is created is decided by the class implementing this
     * interface.  If the file with the given <code>fileName</code> already
     * exists, its contents is overwritten.
     * </p>
     *
     * @param pathName a path name of the nested folder that contains the file
     * @param fileName a name for the file to be created
     * @param source an input stream with the file contents
     * @return reference to the file with the requested <code>fileName</code>
     * and contents populated from <code>source</code>; <code>null</code>
     * indicates failure
     */
    public IFile makeFile(String pathName, String fileName, InputStream source);
}
