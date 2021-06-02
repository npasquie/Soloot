import './App.css'
import 'bootstrap/dist/css/bootstrap.min.css'
import {Button} from 'react-bootstrap'
import {useEthers} from "@usedapp/core"
import {BrowserRouter as Router, Switch, Route, Link} from "react-router-dom";
import Home from "../Home";

function App() {
    const { activateBrowserWallet, account } = useEthers()

    return (
        <div className="App">
            <Router>
            <h1><Link to="/">Soloot</Link></h1>
            {account ?
                    <Switch>
                        <Route path="/quicksell">

                        </Route>
                        <Route path="/upgrade">

                        </Route>
                        <Route path="/lootbox">

                        </Route>
                        <Route path="/">
                            <Home/>
                        </Route>
                    </Switch>
                :
                <Button
                    variant={"primary"}
                    onClick={()=>{activateBrowserWallet()}}>
                    Activer la connexion Ethereum</Button>
            }
            </Router>
        </div>
    )
}

export default App
