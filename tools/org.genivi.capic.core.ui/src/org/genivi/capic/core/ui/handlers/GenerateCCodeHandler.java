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

import java.util.ArrayList;
import java.util.Iterator;

import javax.inject.Inject;

import org.eclipse.core.commands.AbstractHandler;
import org.eclipse.core.commands.ExecutionEvent;
import org.eclipse.core.commands.ExecutionException;
import org.eclipse.core.resources.IFile;
import org.eclipse.ui.IEditorPart;
import org.eclipse.ui.ISelectionService;
import org.eclipse.ui.IWorkbenchWindow;
import org.eclipse.ui.handlers.HandlerUtil;
import org.eclipse.xtext.ui.editor.XtextEditor;
import org.eclipse.jface.dialogs.MessageDialog;
import org.eclipse.jface.viewers.IStructuredSelection;
import org.genivi.capic.core.FileTypeException;
import org.genivi.capic.core.Generator;
import org.genivi.capic.core.GeneratorException;

/**
 * Our sample handler extends AbstractHandler, an IHandler base class.
 * @see org.eclipse.core.commands.IHandler
 * @see org.eclipse.core.commands.AbstractHandler
 */
public class GenerateCCodeHandler extends AbstractHandler {
    @Inject Generator generator;

    /**
     * The constructor.
     */
    public GenerateCCodeHandler() {
    }

    /**
     * the command has been executed, so extract extract the needed information
     * from the application context.
     */
    public Object execute(ExecutionEvent event) throws ExecutionException {
        ArrayList<IFile> inputFiles = new ArrayList<IFile>();

        IWorkbenchWindow window = HandlerUtil.getActiveWorkbenchWindowChecked(event);
        ISelectionService service = window.getSelectionService();
        if (service.getSelection() instanceof IStructuredSelection) {
            IStructuredSelection selection = (IStructuredSelection) service.getSelection();
            Iterator<?> iter = selection.iterator();
            while (iter.hasNext()) {
                Object object = iter.next();
                if (object instanceof IFile)
                    inputFiles.add((IFile) object);
            }
        } else {
            IEditorPart editor = HandlerUtil.getActiveEditor(event);
            Object object = editor.getEditorInput().getAdapter(IFile.class);
            if (editor instanceof XtextEditor && object instanceof IFile)
                inputFiles.add((IFile) object);
        }

        for (IFile file : inputFiles) {
            try {
                generator.generate(file, new WorkspaceFileMaker(file.getProject()));
            } catch (FileTypeException e) {
                // When a command is executed via a shortcut key, the corresponding
                // selection can include files with deliberate extensions,
                // including unsupported ones.  Silently ignore the latter files.
            } catch (GeneratorException e) {
                MessageDialog.openError(
                        HandlerUtil.getActiveShell(event), "Common API C Generator Error", e.getMessage());
            }
        }
        return null;
    }
}
