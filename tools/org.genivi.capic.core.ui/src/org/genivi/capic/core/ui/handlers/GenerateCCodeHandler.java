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

import javax.inject.Inject;

import org.eclipse.core.commands.AbstractHandler;
import org.eclipse.core.commands.ExecutionEvent;
import org.eclipse.core.commands.ExecutionException;
import org.eclipse.core.resources.IFile;
import org.eclipse.ui.ISelectionService;
import org.eclipse.ui.IWorkbenchWindow;
import org.eclipse.ui.handlers.HandlerUtil;
import org.eclipse.jface.dialogs.MessageDialog;
import org.eclipse.jface.viewers.IStructuredSelection;
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
        IWorkbenchWindow window = HandlerUtil.getActiveWorkbenchWindowChecked(event);
        ISelectionService service = window.getSelectionService();
        if (!(service.getSelection() instanceof IStructuredSelection)) {
            return null;
        }
        IStructuredSelection selection = (IStructuredSelection) service.getSelection();
        if (!(selection.getFirstElement() instanceof IFile)) {
            return null;
        }

        //FIXME: Handle multiple selections
        IFile file = (IFile) selection.getFirstElement();
        try {
            generator.generate(file, new WorkspaceFileMaker(file.getProject()));
        } catch (GeneratorException e) {
            MessageDialog.openError(
                    HandlerUtil.getActiveShell(event), "Common API C Generator Error", e.getMessage());
        }
        return null;
    }
}
