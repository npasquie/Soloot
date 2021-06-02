import {useEthers} from "@usedapp/core"
import {Redirect} from "react-router-dom"

function RedirectIfNotConnected(){
    // const { activateBrowserWallet, account } = useEthers()

    // return(
    //     <>
    //         {account ? <></> : <Redirect to="/"/>}
    //     </>
    // )
    return(<></>)
}

export default RedirectIfNotConnected()
