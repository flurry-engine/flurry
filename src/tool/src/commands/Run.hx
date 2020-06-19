package commands;

import Types.Unit;
import Types.Result;
import Types.Project;

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

    public function run() : Result<Unit>
        return proc.run(project.executable(), []);
}