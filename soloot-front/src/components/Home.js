import {Button} from "react-bootstrap";
import Spacer from "./Spacer";
import {Link} from "react-router-dom";

function Home(){
    return(
        <>
            <Button
                variant={"outline-success"}>
                <Link to="/quicksell">
                    Quicksell
                </Link>
            </Button>
            <Spacer/>
            <Button
                variant={"outline-primary"}
                size={"lg"}>
                <Link to="/upgrade">
                    Upgrade !
                </Link>
            </Button>
            <Spacer/>
            <Button
                variant={"outline-info"}>
                <Link to="/lootbox">
                    Buy a LootBox
                </Link>
            </Button>
        </>
    )
}

export default Home
