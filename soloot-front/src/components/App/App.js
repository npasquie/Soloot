import './App.css'
import 'bootstrap/dist/css/bootstrap.min.css';
import {Button} from 'react-bootstrap'
import {useEthers} from "@usedapp/core";

function App() {
    const { activateBrowserWallet } = useEthers()

    return (
        <div className="App">
            <h1>Soloot</h1>
            <Button
                variant={"primary"}
                onClick={()=>{activateBrowserWallet()}}>
                Activer la connexion Ethereum</Button>
        </div>
    )
}

export default App
