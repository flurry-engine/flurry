package commands;

import Types.Project;
import uk.aidanlee.flurry.api.core.Result;
import uk.aidanlee.flurry.api.core.Unit;

using Utils;
using Safety;

class Run
{
    final proc : Proc;

    final project : Project;

    public function new(_project : Project, _proc : Proc = null)
    {
        proc    = _proc.or(new Proc());
        project = _project;
    }

    public function run() : Result<Unit, String>
        return proc.run(project.executable(), []);
}