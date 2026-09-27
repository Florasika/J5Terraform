param(
    [Parameter(Position=0, Mandatory=$true)]
    [ValidateSet("init","fmt","validate","plan","apply","apply-auto","destroy","output","clean")]
    [string]$Command,

    [string]$Env = "dev"
)

$TF = { docker run --rm -it -v "$(pwd):/workspace" -w /workspace hashicorp/terraform:1.7 @args }

function Invoke-Init     { & $TF init }
function Invoke-Fmt      { & $TF fmt -recursive }
function Invoke-Validate { Invoke-Fmt; & $TF validate }
function Invoke-Plan     { Invoke-Validate; & $TF plan -var="environnement=$Env" -out=tfplan }
function Invoke-Apply    { Invoke-Plan; & $TF apply tfplan }
function Invoke-ApplyAuto { & $TF apply -var="environnement=$Env" -auto-approve }
function Invoke-Destroy  { & $TF destroy -var="environnement=$Env" -auto-approve }
function Invoke-Output   {
    $json = & $TF output -json
    $json | ConvertFrom-Json | ConvertTo-Json -Depth 10
}
function Invoke-Clean {
    Remove-Item -Recurse -Force .terraform, terraform.tfstate*, tfplan, output -ErrorAction SilentlyContinue
}

switch ($Command) {
    "init"       { Invoke-Init }
    "fmt"        { Invoke-Fmt }
    "validate"   { Invoke-Validate }
    "plan"       { Invoke-Plan }
    "apply"      { Invoke-Apply }
    "apply-auto" { Invoke-ApplyAuto }
    "destroy"    { Invoke-Destroy }
    "output"     { Invoke-Output }
    "clean"      { Invoke-Clean }
}
